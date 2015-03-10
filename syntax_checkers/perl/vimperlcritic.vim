"============================================================================
"File:        vimperlcritic.vim
"Description: Syntax checking plugin for syntastic.vim
"Maintainer:  LCD 47 <lcd047 at gmail dot com>
"License:     This program is free software. It comes without any warranty,
"             to the extent permitted by applicable law. You can redistribute
"             it and/or modify it under the terms of the Do What The Fuck You
"             Want To Public License, Version 2, as published by Sam Hocevar.
"             See http://sam.zoy.org/wtfpl/COPYING for more details.
"
"============================================================================

if exists("g:loaded_syntastic_perl_vimperlcritic_checker")
    finish
endif
let g:loaded_syntastic_perl_vimperlcritic_checker = 1

let s:save_cpo = &cpo
set cpo&vim

" Checker options {{{1

if !exists('g:syntastic_perl_vimperlcritic_thres')
    let g:syntastic_perl_vimperlcritic_thres = 5
endif

if !exists('g:syntastic_perl_vimperlcritic_format')
    let g:syntastic_perl_vimperlcritic_format = '(%s) %m (%e)'
endif

" }}}1

function! SyntaxCheckers_perl_vimperlcritic_IsAvailable() dict " {{{1
    let rc = 0

    if has('perl')
        perl <<EOT
            no strict;
            no warnings;

            my $rc = eval {
                require Perl::Critic;
                Perl::Critic->import();
                require Exception::Class;
                Exception::Class->import();
                1;
            } || 0;

            VIM::DoCommand('let rc = ' . $rc);

            sub quote {
                my $str = shift;
                $str =~ s/'/''/go; # '
                return "'$str'";
            }
EOT
    endif

    return has('perl') && rc
endfunction " }}}1

function! SyntaxCheckers_perl_vimperlcritic_GetLocList() dict " {{{1
    let loclist = []
    let rc = 0

    perl <<EOT
	no strict;
	no warnings;

        my $res = eval {
            $format = VIM::Eval('g:syntastic_perl_vimperlcritic_format');
            Perl::Critic::Violation::set_format($format);

            my $code       = join '', map { $_ . "\n" } $main::curbuf->Get( 1 .. $main::curbuf->Count() );
            my $critic     = Perl::Critic->new();
            my @violations = $critic->critique( \$code );
            my $thresh     = VIM::Eval('g:syntastic_perl_vimperlcritic_thres');

            for my $v (@violations) {
                my %err = ();
                my $fn  = $v->filename();

                if   ( defined $fn ) { $err{filename} = quote $fn; }
                else                 { $err{bufnr}    = $main::curbuf->Number(); }

                $err{lnum}    = $v->line_number();
                $err{col}     = $v->column_number();
                $err{text}    = quote( $v->to_string() );
                $err{type}    = quote( $v->severity() < $thresh ? 'W' : 'E' );
                $err{vcol}    = 0;
                $err{valid}   = 1;
                $err{subtype} = quote( 'Style' );

                my $dict = join ', ', map { "'$_': " . $err{$_} } keys %err;
                VIM::DoCommand("call add(loclist, { $dict })");
            }

            undef @violations;
            undef $critic;
            undef $code;

            1;
        } || 0;

        VIM::DoCommand('let rc = ' . $res);

        if (my $e = Exception::Class->caught('Perl::Critic::Exception')) {
            VIM::DoCommand('call syntastic#log#error(' . quote('checker perl/vimperlcritic: ' . $e->full_message()) . ')' );
        }
EOT

    return rc ? loclist : []
endfunction " }}}1

call g:SyntasticRegistry.CreateAndRegisterChecker({
    \ 'filetype': 'perl',
    \ 'name': 'vimperlcritic',
    \ 'exec': ''})

let &cpo = s:save_cpo
unlet s:save_cpo

" vim: set sw=4 sts=4 et fdm=marker:
