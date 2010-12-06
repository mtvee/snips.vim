"
"        Name: snips.vim
"     Version: 0.0.1
"      Author: J Knight <emptyvee AT gmail DOT com>
" Last Change: 2010-12-05 Sun 09:14 PM
"
" Description:
"   simple snippets, a la textmate, for vim
"
"   Snippets are text files located in: 
"      '~/.vim/snips/FILETYPE/NAME.snip'
"
"   Snippets replace the trigger word that the cursor is on, verbatim, and can
"   also do some simple template expansions (see below).
"
" Example:
"
"   If the cursor is on the word 'fun' in a vim buffer, 
"   ':call ExpandSnippet()' will look for a file called:
"   '~/.vim/snips/vim/fun.snip' and, if found, will insert it
"   into the buffer, replacing the word 'fun' under the cursor
"   with whatever is in the 'fun.snip' file.
"
" Usage:
"   :call ExpandSnippet()
"
"   nmap <F2> :call ExpandSnippet()<CR>
"   imap <F2> <Esc>:call ExpandSnippet()<CR>i
"
" Template Syntax:
"   <%eval:code%>
"     will expand to the result value of 'code'
"     e.g. <%eval:strftime('%Y-%m-%d')%>
"
"   <%date%>
"     expands to current date (%Y-%m-%d)
"
"   <%time%>
"     expands to current time (%I:%M %p)
"
"   <%timestamp%>
"     expands to rfc822 style datetime
"
"   <%path%>
"     will expand to the current file path
"
"   <%filename%>
"     will expand to the current filename
"
"   <%username%>
"     attempt to return the username. Cross plat is always
"     fun so, if the plat is not supported yet it returns
"     the word 'USERNAME'
"
" Credits:
"   Tyru - vimtemplate 
"     http://www.vim.org/scripts/script.php?script_id=2615
"   Michael Sanders - SnipMate
"     http://www.vim.org/scripts/script.php?script_id=2540
"
" Change Log:
"   0.0.1: Initial script
"
" -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

if exists("did_load_snips")
  finish
endif

let did_load_snips = 1

" save coptions
let s:cpo_save = &cpo

if !exists("g:snips_base_dir")
  let g:snips_base_dir = split(&rtp,',')[0].'/snips'
endif

"
" init this script
" - make sure we have a snips directory
"
fun! s:init_snips()
  if !isdirectory(g:snips_base_dir)
    call mkdir(g:snips_base_dir)
  endif
  return 1
endfunction

"
" return true if we have a dir for the passed in filetype
"
fun! s:have_filetype( filetype )
  if isdirectory(g:snips_base_dir.'/'.a:filetype)
    return 1
  endif
  return 0
endfunction

"
" Try and return the username from the OS, always a good time
"
fun! s:get_username()
  if has('win16') || has('win32') || has('win64')
    return expand($USERNAME) . '@' . expand($COMPUTERNAME)
  elseif has('unix') || has('macunix') || has('win32unix')
    return expand($USER) . '@' . substitute(system('hostname'), "\n", '', '')
  else
    return "USERNAME"
  endif
endfunction

" 
" expand a line of text, replacing placeholders like <% PLACEHOLDER %> with
" stuff
"
fun! s:expand_line( line, path )
  let line = a:line
  let regex = '\m<%\s*\(.\{-}\)\s*%>'
  let path = expand('%') == '' ? a:path : expand('%')
  let replaced = ''

  let mlist = matchlist( line, regex )
  call filter( mlist, '! empty(v:val)' )

  while !empty( mlist )
    if mlist[1] =~# '\m\s*eval:'
      let code = substitute(mlist[1], '\m\s*eval:', '', '')
      let replaced = eval( code )
    else
      if mlist[1] ==# 'path'
        let replaced = path
      elseif mlist[1] ==# 'filename'
        let replaced = fnamemodify( path, ':t' )
      elseif mlist[1] ==# 'date'
        let replaced = strftime("%Y-%m-%d")
      elseif mlist[1] ==# 'time'
        let replaced = strftime("%I:%M %p")
      elseif mlist[1] ==# 'timestamp'  
        let replaced = strftime("%a, %d %b %Y %H:%M:%S %z")
      elseif mlist[1] ==# 'username'  
        let replaced = s:get_username()
      endif
    endif
    let line = substitute( line, regex, replaced, '')
    let mlist = matchlist( line, regex )
    call filter( mlist, '! empty(v:val)')
  endwhile

  return line
endfunction

" 
" Try and find a snippet that matches the word at the cursor and insert it
"
fun! ExpandSnippet( )
  if !s:init_snips()
    return
  endif
  let word = expand("<cword>")
  if !empty(word) && word =~ '[A-Za-z0-9_-]' && s:have_filetype(&ft)
    let snip_file = g:snips_base_dir.'/'.&ft.'/'.word.'.snip'
    if filereadable( snip_file )
      " read in the file
      let text = readfile( snip_file )
      " walk through each line and try and expand any template
      " placeholders found in there
      let [i, len] = [0, len(text)]
      while i < len
        let text[i] = s:expand_line( text[i], expand('%') )
        let i = i + 1
      endwhile
      " delete the word at the cursor
      execute "normal daw"
      " and stuff in the lines
      call append( line("."), text )
      return 1
    endif
  endif
  return 0
endfunction

" restore coptions
let &cpo = s:cpo_save
unlet s:cpo_save


