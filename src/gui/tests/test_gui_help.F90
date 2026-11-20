!< GUI test, headless: the Help window shows the user guide, and the Help menu brings it forward.
program test_gui_help
!< GUI test, headless: the Help window shows the user guide, and the Help menu brings it forward.
!<
!< The text is docs/guide/gui-user.md as scripts/gui_help.py compiles it in (run_gui_tests.sh checks the include against
!< the page first); here: the document holds it, its headings are found by the search, a heading is scrolled to, the
!< menus Help > User guide and Help > About work.
use, intrinsic :: iso_fortran_env, only : int32
use figure,                        only : app_object
use figure_testing,                only : test_menu_click, test_run, test_item_exists, test_popup_rect, &
                                          test_item_click, test_id_conflicts, test_unnamed_items
use appelbe_gui_app,               only : gui_object, WINDOW_HELP
use appelbe_gui_help,              only : help_text
use gui_assert,                    only : check, check_summary

implicit none
type(app_object)              :: app   !< Application, headless.
type(gui_object)              :: gui   !< The GUI.
character(len=:), allocatable :: text  !< The guide.
logical                       :: found !< A popup is open.
real(8)                       :: x0, y0, x1, y1 !< Popup rectangle.
character(len=:), allocatable :: list(:) !< Unnamed items.
integer(int32)                :: n, k, i !< Counts, counter.

call app%init_headless(1280_int32, 860_int32)
call app%set_checks('abort')
call gui%init()
call run()
text = help_text()
call check('the guide is compiled in (its title, its sections)', index(text, '# Using appelbe-gui') == 1 .and. &
           index(text, '## Load an INDACO table') > 0 .and. index(text, '## When something goes wrong') > 0)
call check('no front matter, no picture left', index(text, 'title:') == 0 .and. index(text, '![') == 0)
call check('links to other pages made absolute', index(text, '](https://szaghi.github.io/appelbe/guide/gui-install)') > 0)
call check('the Help window holds the guide', gui%help%text() == text)

call test_menu_click('//##MainMenuBar/Help/User guide')
call run()
call check('Help > User guide: the Help window in front', test_item_exists(WINDOW_HELP//'/guide'))
call check('Help: no id conflict', test_id_conflicts() == 0_int32)
! FIGURE v0.8.0's markdown view names neither its contents' entries nor its hide and edge handles (##entry, ##hide,
! ##edge, under the document's id 'guide'): FIGURE's, not this program's; every item of the GUI's own must be named
n = test_unnamed_items(list)
k = count([(index(list(i), '/Help/guide/') == 0, i = 1, n)])
if (k > 0) print '(A)', ('  unnamed: '//trim(list(i)), i = 1, n)
call check('Help: every item of the GUI named (the markdown view''s own excepted)', k == 0_int32)
call gui%help%find('INDACO')
call run()
call check('the search finds INDACO', gui%help%matches() > 0)
call gui%help%find('')
call gui%help%scroll_to('When something goes wrong')
call run()

call test_menu_click('//##MainMenuBar/Help/About appelbe-gui')
call run()
call test_popup_rect(x0, y0, x1, y1, found)
call check('Help > About: its box opens', found)
call test_item_click('About appelbe-gui/Close')
call run()
call test_popup_rect(x0, y0, x1, y1, found)
call check('About: Close closes it', .not. found)

call gui%destroy()
call app%destroy()
call check_summary()

contains
   subroutine run()
   !< Draw frames until the interface is idle, then one more.
   do while (test_run(400_int32))
      if (.not. app%next_frame()) exit
      call gui%frame(app)
   enddo
   if (app%next_frame()) call gui%frame(app)
   endsubroutine run
endprogram test_gui_help
