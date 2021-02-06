" /* vim: set et sw=4 sts=4: */
" # vim: noet sw=8 sts=8
" vim: et sw=4 sts=4
set modeline
set cpoptions+=u
" set expandtab
set tabstop=8
set shiftwidth=8
set softtabstop=8
set termencoding=utf-8
set encoding=utf-8
set fileencodings=iso-2022-jp,utf-8,euc-jp,cp932
set ffs=unix,dos,mac
set ambiwidth=double
set wrap
" set nowrap
set sidescroll=4
set listchars+=precedes:<,extends:>
set nobomb
set colorcolumn=81

set hlsearch
nmap <ESC>u :nohl<CR>
nmap <ESC><ESC> :nohl<CR>
nmap <ESC>w :set wrap!<CR>
nmap <ESC>8 :call ToggleColorColumn()<CR>

syntax on

let s:useColorColumn = 1
let s:colorColumnPos = 81
let s:useColorColumnResizeTrick = 0
if s:useColorColumn
    function! ToggleColorColumn()
        if winwidth(0) >= s:colorColumnPos
            " Type of &colorcolumn variable is string
            if &colorcolumn == '' || &colorcolumn == '0'
                exe 'set colorcolumn=' . s:colorColumnPos
                echomsg printf('%d columns are shown in RED', s:colorColumnPos)
                return
            endif
        else
            if &colorcolumn == ''
                set colorcolumn=0
                echomsg printf('%d columns are shown when width > %d',
                             \ s:colorColumnPos, s:colorColumnPos - 1)
                return
            endif
        endif
        set colorcolumn=
        echomsg 'No specific columns are colored'
    endfunction
    function! ResetColorColumn()
        if &colorcolumn != ''
            if winwidth(0) >= s:colorColumnPos
                exe 'set colorcolumn=' . s:colorColumnPos
            else
                set colorcolumn=0
            endif
            " The following items are the verification results when
            " 's:useColorColumnResizeTrick' is set to 1.
            "   - 'redraw!' clears echo line.
            "   - 'redraw' and 'redraw!' have no effect when the window (not
            "     splited window) width changes from (less than 81) to 81.
            redraw
        endif
        if s:useColorColumnResizeTrick
            return winwidth(0)
        endif
    endfunction
    "
    " The 'VimResized' event is available when the window (such as xterm) size
    " is resized, but not when the split window is resized. The following URI
    " shows a trick available in this case.
    " https://vi.stackexchange.com/questions/22687
    "
    " However, when the trick is applied, it seems that the cursor speed is
    " slightly slowed down probably because 'redraw' occurs frequently.
    "
    " When applying the trick, set the value of 's:useColorColumnResizeTrick'
    " variable just above to 1. Otherwise set it to 0.
    "
    if has('autocmd') && !s:useColorColumnResizeTrick
        autocmd VimResized * call ResetColorColumn()
    endif
endif

if &term == 'mlterm' || &term == 'xterm-color'
    highlight Statement ctermfg=DarkGray
endif

if has('autocmd')
    function! AU_ReCheck_FENC()
        if &fileencoding == 'iso-2022-jp' && search("[^\x01-\x7e]", 'n') == 0
            let &fileencoding=&encoding
        endif
    endfunction
    autocmd BufReadPost * call AU_ReCheck_FENC()
endif

function! GetStatusEx()
    let str = ''
    let str = str . '' . &fileformat . ']'
    if has('multi_byte') && &fileencoding != ''
        let str = &fileencoding . ':' . str
    endif
    if &bomb
       let str = 'bom:' . str
    endif
    let str = '[' . str
    return str
endfunction

set laststatus=2
set statusline=%y%{GetStatusEx()}\ %f\ %m%r%=<%c:%l>

if s:useColorColumn && s:useColorColumnResizeTrick
    set statusline=%y%{GetStatusEx()}\ %f\ %m%r%=<%c/%{ResetColorColumn()}:%l>
endif
