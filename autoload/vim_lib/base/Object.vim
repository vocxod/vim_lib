" Date Create: 2015-01-06 13:26:24
" Last Change: 2015-01-08 23:05:50
" Author: Artur Sh. Mamedbekov (Artur-Mamedbekov@yandex.ru)
" License: GNU GPL v3 (http://www.gnu.org/copyleft/gpl.html)

"" {{{
" Объект представляет базовый класс для всех классов библиотеки.
" Для инстанциации данного класса или его подклассов используется метод new, который создает и инициализирует объект класса.
" Отличительной особенностью объекта является наличие свойства class, которое ссылается на класс, экземпляром которого является объект. Классы этого свойства не имеют.
"" }}}
let s:Class = {}

"" {{{
" Метод создает дочерний по отношению к вызываемому классу класс.
" Для создаваемого дочернего класса определено статичное свойство parent, ссылающееся на вызываемый (родительский класс).
" Все методы вызываемого (родительского) класса копируются в создаваемый дочерний класс.
" @return hash Класс, являющийся дочерним по отношению к вызываемому классу.
"" }}}
function! s:Class.expand() " {{{
  let l:child = {'parent': self}
  " Перенос ссылок на методы класса в подкласс. {{{
  let l:child.expand = self.expand
  let l:child.new = self.new
  let l:child.bless = self.bless
  let l:child.typeof = self.typeof
  " }}}
  return l:child
endfunction " }}}

"" {{{
" Метод создает неинициализированный экземпляр вызываемого класса.
" Метод устанавливает свойства class и parent объекта в соответствии с требованиями экземпляра класса.
" Метод копирует методы класса в объект.
" @param hash parent [optional] Инициализированный экземпляр родительского класса. Если параметр не задан, используется конструктор по умолчанию для родительского класса.
" @return hash Неинизиализированный экземпляр класса.
"" }}}
function! s:Class.bless(...) " {{{
  let l:obj = {'class': self, 'parent': (exists('a:1'))? a:1 : self.parent.new()}
  " Перенос частных методов из класса в объект. {{{ 
  for l:p in keys(self)
    if type(self[l:p]) == 2 && index(['expand', 'bless', 'new', 'typeof'], l:p) == -1
      let l:obj[l:p] = self[l:p]
    endif
  endfor
  " }}}
  return l:obj
endfunction " }}}

"" {{{
" Метод создает экземпляр вызываемого класса.
" Метод сохраняет ссылку на инстанциируемый (вызываемый) класс в свойстве class объекта.
" Если инстанциируемый (вызываемый) класс является дочерним, метод создает ссылку на объект родительского класса в свойстве parent объекта.
" Метод не копирует методы в экземпляры класса, потому следует сделать это в самостоятельно.
" Данный метод может быть переопределен в дочерних классах с определением аргументов, используемых для инициализации объекта. Делается это следующим образом:
"   function! s:Child.new(a, b)
"     let s:obj = self.bless(self.parent.new(a:a)) " Создание объекта через вызов конструктора родительского класса.
"     let s:obj.b = a:b " Инициализируемое свойство объекта.
"     let s:obj.c = 1   " Не инициализируемое свойство объекта.
"     return s:obj
"   endfunction
" @return hash экземпляр вызываемого класса.
"" }}}
function! s:Class.new() " {{{
  if has_key(self, 'parent')
    let l:obj = self.bless()
  else
    let l:obj = {'class': self}
  endif
  return l:obj
endfunction " }}}

"" {{{
" Метод определяет, является ли вызываемый класс дочерним по отношению к данному.
" @param hash type Целевой класс.
" @return bool Если вызываемый класс является целевым или его потомком, метод возвращает 1, иначе 0.
"" }}}
function! s:Class.typeof(type) " {{{
  let l:currentClass = self
  while l:currentClass != a:type
    if !has_key(l:currentClass, 'parent')
      return 0
    endif
    let l:currentClass = l:currentClass.parent
  endwhile
  return 1
endfunction " }}}

let g:vim_lib#base#Object# = s:Class
