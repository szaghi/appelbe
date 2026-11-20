!< Expected failure: kinetic_operator%init without stat still stops on an input it rejects (an even n_nodes).
program test_xfail_init_stop
!< Expected failure: kinetic_operator%init without stat still stops on an input it rejects (an even n_nodes).
!<
!< scripts/run_tests.sh counts a non-zero exit of an *_xfail_* program as XFAIL (success): the default behaviour of the
!< batch drivers, which pass no stat, is unchanged by the stat argument the GUI uses (test_errors).
use penf,            only : I4P
use appelbe_kinetic, only : kinetic_params, kinetic_operator

implicit none
type(kinetic_params)   :: par !< Defaults, no fast ions.
type(kinetic_operator) :: op  !< Operator.

call op%init(par=par, n_nodes=400_I4P)
endprogram test_xfail_init_stop
