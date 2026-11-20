!< The in-app help of appelbe-gui: the user guide, docs/guide/gui-user.md, compiled into the program.
module appelbe_gui_help
!< The in-app help of appelbe-gui: the user guide, docs/guide/gui-user.md, compiled into the program.
!<
!< One source: scripts/gui_help.py writes appelbe_gui_help.inc from the guide (front matter and pictures dropped, links
!< to other pages made absolute); run_gui_tests.sh checks that the include is up to date. A packaged program has no
!< repository to read the page from, so the text is in the program.

implicit none
private
public :: help_text, HELP_SITE

character(len=*), parameter :: HELP_SITE = 'https://szaghi.github.io/appelbe/guide/gui-user' !< The guide online.

contains
   pure function help_text() result(t)
   !< The user guide, Markdown.
   character(len=:), allocatable :: t !< The text.

   include 'appelbe_gui_help.inc'
   endfunction help_text
endmodule appelbe_gui_help
