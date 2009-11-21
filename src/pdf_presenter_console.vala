/**
 * Main application file
 *
 * This file is part of pdf-presenter-console.
 *
 * pdf-presenter-console is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3 of the License.
 *
 * pdf-presenter-console is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 * or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
 * more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * pdf-presenter-console; if not, write to the Free Software Foundation, Inc.,
 * 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */
/* Using Poppler for PDF rendering in Vala sample code */

using Gtk;

namespace org.westhoffswelt.pdfpresenter {

/**
 * Pdf Presenter Console main application class
 *
 * This class contains the main method as well as all the logic needed for
 * initializing the application, like commandline parsing and window creation.
 */
public class Application: GLib.Object {
	
    /**
     * Window which shows the current slide in fullscreen
     *
     * This window is supposed to be shown on the beamer
     */
	private PresentationWindow presentation_window;

    /**
     * Presenter window showing the current and the next slide as well as
     * different other meta information useful for the person giving the
     * presentation.
     */
	private PresenterWindow presenter_window;

    /**
     * Global mutex used by all threads, to lock the operations on the poppler
     * library, which is unfortunately not threadsafe, therefore only one
     * poppler call at a time is possible.
     */
	public static GLib.Mutex poppler_mutex = new GLib.Mutex();

    /**
     * Commandline option specifying if the presenter and presentation screen
     * should be switched.
     */
    protected static bool display_switch = false;
    
    /**
     * Commandline option which allows the complete disabling of slide caching
     */
    protected static bool disable_caching = false;

    /**
     * Commandline option providing the talk duration, which will be used to
     * display a timer
     */
    protected static uint duration = 45;

    /**
     * Commandline option parser entry definitions
     */
    const OptionEntry[] options = {
        { "duration", 'd', 0, OptionArg.INT, ref Application.duration, "Duration in minutes of the presentation used for timer display. (Default 45 minutes)", "N" },
        { "switch-screens", 's', 0, 0, ref Application.display_switch, "Switch the presentation and the presenter screen.", null },
        { "disable-cache", 'c', 0, 0, ref Application.disable_caching, "Disable caching and pre-rendering of slides to save memory on cost of speed.", null },
        { null }
    };

    /**
     * Parse the commandline and apply all found options to there according
     * static class members.
     *
     * On error the usage help is shown and the application terminated with an
     * errorcode 1
     */
    protected void parse_command_line_options( string[] args ) {
        var context = new OptionContext( "<pdf-file>" );

        context.add_main_entries( options, null );
        
        try {
            context.parse( ref args );
        }
        catch( OptionError e ) {
            stderr.printf( "\n%s\n\n", e.message );
            stderr.printf( "%s", context.get_help( true, null ) );
            Posix.exit( 1 );
        }

        if ( args.length != 2 ) {
            stderr.printf( "%s", context.get_help( true, null ) );
            Posix.exit( 1 );
        }
    }

    /**
     * Main application function, which instantiates the windows and
     * initializes the Gtk system.
     */
    public void run( string[] args ) {
        stdout.printf( "Pdf-Presenter-Console Version 1.0 Copyright 2009 Jakob Westhoff\n" );

		Gdk.threads_init();
        Gtk.init( ref args );

        this.parse_command_line_options( args );

        stdout.printf( "Initializing pdf rendering...\n" );
        
        int presenter_monitor, presentation_monitor;
        if ( Application.display_switch != true ) {
            presenter_monitor    = 0;
            presentation_monitor = 1;
        }
        else {
            presenter_monitor    = 1;
            presentation_monitor = 0;
        }

        var controller = new PresentationController();
        var cache_status = new CacheStatus();

        if ( Gdk.Screen.get_default().get_n_monitors() > 1 ) {
            this.presenter_window = new PresenterWindow( args[1], presenter_monitor );
            controller.set_presenter_window( this.presenter_window );
            this.presenter_window.set_presentation_controller( controller );
            this.presenter_window.set_cache_observer( cache_status );
        }
        else {
            stdout.printf( "Only one screen detected falling back to simple presentation mode.\n" );
            presentation_monitor = 0;
        }

        this.presentation_window = new PresentationWindow( args[1], presentation_monitor );

        controller.set_presentation_window( this.presentation_window );
        this.presentation_window.set_presentation_controller( controller );
        this.presentation_window.set_cache_observer( cache_status );

		// The windows are always displayed at last to be sure all caches have
		// been created at this point.
        this.presentation_window.show_all();
        
		if ( this.presenter_window != null ) {
			this.presenter_window.show_all();
		}

		Gdk.threads_enter();
        Gtk.main ();
		Gdk.threads_leave();
    }

    /**
     * Basic application entry point
     */
    public static int main ( string[] args ) {
        var application = new Application();
		application.run( args );

        return 0;
    }
}

}