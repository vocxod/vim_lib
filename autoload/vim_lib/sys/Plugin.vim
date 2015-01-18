" Date Create: 2015-01-09 13:58:18
" Last Change: 2015-01-18 11:19:53
" Author: Artur Sh. Mamedbekov (Artur-Mamedbekov@yandex.ru)
" License: GNU GPL v3 (http://www.gnu.org/copyleft/gpl.html)

let s:Object = g:vim_lib#base#Object#
let s:NullPlugin = g:vim_lib#sys#NullPlugin#

"" {{{
" Объекты данного класса представляют каждый конкретный, подключаемый редактором плагин.
" Такой плагин можно отключить, определив переменную: let имяПлагина# = 0 - в файле .vimrc или скриптах каталога 'plugin'. При этом все опции, команды и привязки плагина, определенные в нем по умолчанию, не будут применены.
" Плагин, использующий данный класс, инициализируется в каталоге 'plugin' редактора и может выглядить следующим образом:
"   let s:Plugin = vim_lib#sys#Plugin#
"   let s:p = s:Plugin.new('myPlugin', '1.0')
"   ... " Значения свойств, а так же команды и привязки, используемые по умолчанию для данного плагина.
"   let s:p.reg()
" Интерфейс плагина описывается в каталоге 'autoload' редактора и может выглядить следующим образом:
"   function! myPlugin#method()
"     echo g:myPlugin#optionA
"   endfunction
"" }}}
let s:Class = s:Object.expand()
let s:Class.plugins = {}

function! s:Class.__verifyDep(dep) " {{{
  if has_key(a:dep, 'version') && !self.__verifyVersion(a:dep['version'])
    return 0
  endif
  if has_key(a:dep, 'has') && !self.__verifyEnv(a:dep['has'])
    return 0
  endif
  if has_key(a:dep, 'plugins') && !self.__verifyPlugs(a:dep['plugins'])
    return 0
  endif
  return 1
endfunction " }}}

function! s:Class.__verifyVersion(assertVersion) " {{{
  if v:version < a:assertVersion
    echohl Error | echo 'Module ' . self.currentModule . ': You need Vim v' . a:assertVersion . ' or higher.' | echohl None
    return 0
  endif
  return 1
endfunction " }}}

function! s:Class.__verifyEnv(assertEnv) " {{{
  for l:module in a:assertEnv
    if !has(l:module)
      echohl Error | echo 'Module ' . self.currentModule . ': You need module "' . l:module . '".' | echohl None
      return 0
    endif
  endfor
  return 1
endfunction " }}}

function! s:Class.__verifyPlugs(assertPlugins) " {{{
  for l:plugin in a:assertPlugins
    if !has_key(self.plugins, l:plugin)
      echohl Error | echo 'Module ' . self.currentModule . ': You need plugin "' . l:plugin . '".' | echohl None
      return 0
    endif
  endfor
  return 1
endfunction " }}}

"" {{{
" Конструктор, формирующий объектное представление плагина.
" После инициализации плагина необходимо вызвать метод reg.
" Если плагин с заданным именем уже зарегистрирован, метод возвращает его объектное представление, созданное ранее. При этом версия, задаваемая вторым параметром, не применяется.
" @param string name Имя плагина.
" @param string version Версия плагина.
" @param hash dependency [optional] Зависимости плагина. Словарь может иметь следующую структуру: {'version': версияРедактора, 'has': [модулиОкружения], 'plugins': [плагины]}
" @return vim_lib#sys#Plugin# Целевой плагин.
"" }}}
function! s:Class.new(name, version, ...) " {{{
  " Получение объекта из пула. {{{
  if has_key(self.plugins, a:name)
    return self.plugins[a:name]
  endif
  " }}}
  let self.currentModule = a:name
  if exists('g:' . a:name . '#') && type(g:[a:name . '#']) == 0
    return s:NullPlugin.new(a:name)
  endif
  if exists('a:1') && !self.__verifyDep(a:1)
    return s:NullPlugin.new(a:name)
  endif
  let l:obj = self.bless()
  let l:obj.name = a:name
  let l:obj.version = a:version
  let l:obj.savecpo = &l:cpo
  let self.plugins[a:name] = l:obj
  set cpo&vim
  return l:obj
endfunction " }}}

"" {{{
" Метод возвращает имя плагина.
" @return string Имя плагина.
"" }}}
function! s:Class.getName() " {{{
  return self.name
endfunction " }}}

"" {{{
" Метод возвращает адрес каталога плагина.
" @return string Адрес каталога плагина.
"" }}}
function! s:Class.getPath() " {{{
  return self.path
endfunction " }}}

"" {{{
" Метод возвращает версию модуля.
" @return string Версия модуля.
"" }}}
function! s:Class.getVersion() " {{{
  return self.version
endfunction " }}}

"" {{{
" Метод определяет начальное значение свойства плагина. Он может применяться для определения свойств плагина по умолчанию.
" Переопределить свойства плагина можно двумя способами:
" 1. Если плагин еще не был загружен (на пример для файла '.vimrc' или скриптов каталога 'plugin'), можно определить словарь 'имяПлагина#', элементы которого определят значения опций плагина. На пример так:
"   let myPlugin# = {'a': 1}
" 2. Если плагин уже был загружен (на пример для скриптов каталога 'ftplugin'), можно непосредственно переопределить свойства объекта плагина, на пример так:
"   let myPlugin#.a = 1
" @param string option Имя свойства.
" @param mixed value Значение по умолчанию для данного свойства.
"" }}}
function! s:Class.def(option, value) " {{{
  let self[a:option] = a:value
endfunction " }}}

"" {{{
" Метод определяет команды редактора, создаваемые плагином.
" При выполнении этих команд будут вызываться методы плагина, определенные в его интерфейсе. Так, команда вида:
"   call s:p.comm('MyPlugComm', 'methodA')
" выполнит метод 'MyPluginComm#methodA'.
" Команды не будут созданы, если плагин отключен.
" @param string command Команда.
" @param string method Имя метода, являющегося частью интерфейса плагина.
"" }}}
function! s:Class.comm(command, method) " {{{
  exe 'command! -nargs=? ' . a:command . ' call ' . self.getName() . '#' . a:method . '()'
endfunction " }}}

"" {{{
" Метод определяет горячие клавиши, создаваемые плагином.
" При использовании этих привязок будут вызываться методы плагина, определенные в его интерфейсе. Так, привязка вида:
"   call s:p.map('n', 'q', 'quit')
" выполнит метод 'MyPluginComm#quit'.
" Привязки не будут созданы, если плагин отключен.
" @param string mode Режим привязки. Возможно одно из следующих значений: n, v, o, i, l, c.
" @param string sequence Комбинация клавишь, для которой создается привязка.
" @param string method Имя метода, являющегося частью интерфейса плагина.
"" }}}
function! s:Class.map(mode, sequence, method) " {{{
  exe a:mode . 'noremap ' . a:sequence . ' :call ' . self.getName() . '#' . a:method . '()<CR>'
endfunction " }}}

"" {{{
" Метод регистрирует плагин в системе и восстанавливает систему в начальное состояние.
" Данный метод необходимо вызвать в конце файла инициализации плагина.
"" }}}
function! s:Class.reg() " {{{
  " Переопределение локальных опций плагина путем объединения словарей и запись его в глобальный объект имяПлагина#.
  let g:[self.name . '#'] = extend(self, (exists('g:' . self.name . '#'))? g:[self.name . '#'] : {})
  call self.run()
  let &l:cpo = self.savecpo
endfunction " }}}

"" {{{
" Данный метод может быть переопределен конкретным плагином с целью реализации логики.
"" }}}
function! s:Class.run() " {{{
endfunction " }}}

let g:vim_lib#sys#Plugin# = s:Class
