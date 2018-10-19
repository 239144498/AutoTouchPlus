---- AutoTouchPlus stuff and things.
-- @module AutoTouchPlus
-- @author Djordje Pepic
-- @license Apache 2.0
-- @copyright Djordje Pepic 2018
-- @usage require("AutoTouchPlus")

abs = math.abs
unpack = table.unpack
local _string_converters = {}
local _metamethods = {
'__add', '__sub', '__mul', '__div', '__idiv', '__pow',
'__mod', '__concat', '__index', '__newindex', '__call',
'__pairs', '__ipairs', '__tostring', '__len',
'__mode', '__metatable', '__gc'
}

local classes = {}
local private_tables = {}

function class(name, ...)
local c --a new class type
local bases, getters, setters = {}, {}, {}
for i, v in pairs({...}) do
if is.str(v) then v = classes[v] end
table.insert(bases, v)
end

--returns unique table upon intialization
--not seen to class instance unless indexed specifically with <instance>.__private
getters.__private = function(self, value)
local key = tostring(self)
if not private_tables[key] then
private_tables[key] = {}
end
return private_tables[key]
end

--protect the __private table
setters.__private = function()
error('Cannot set __private table')
end

--class constructor
local function constructor(cls, ...)
local self = {}
local table_string = tostring(self)
setmetatable(self, c)

if cls.__init then
cls.__init(self, ...)
end

self.__getters.__base_repr = function(s) return table_string end
return self
end

--class object searches in object first, then in class for value
local function class_meta_index(cls, value)
return rawget(cls, value) or rawget(c, value)
end

--can only set values of class object
local function class_meta_newindex(cls, key, value)
rawset(cls, key, value)
end

c = {
__name = name,
__bases = bases,
__getters = getters,
__setters = setters,
__index = getattr,
__newindex = setattr,
__repr = _string_converters.class_repr,
__tostring = _string_converters.class_str,
-- convience methods
copy = copy,
isinstance = isinstance
}

-- copy any methods/properties from base classes in order of inheritance (youngest first)
for _, base in pairs(bases) do
for k, v in pairs(base) do
if not c[k] then c[k] = v end
for _, meth in pairs(_metamethods) do
if base[meth] and (meth == '__index' or meth == '__newindex' or meth == '__tostring' or not c[meth]) then
c[meth] = base[meth]
end
end
end
for k, v in pairs(base.__getters) do
if not c.__getters[k] then c.__getters[k] = v end
end
for k, v in pairs(base.__setters) do
if not c.__setters[k] then c.__setters[k] = v end
end
end

classes[name] = setmetatable(c, {
__class = c,
__call = constructor,
__index = class_meta_index,
__newindex = class_meta_newindex,
__repr = _string_converters.class_repr,
})
return classes[name]
end

function getattr(cls, value)
if cls and isType(cls, 'table') then
local mt = getmetatable(cls)
local primary = rawget(cls, value)
if primary then
return primary
elseif mt then
local fallback = rawget(mt, value)
if mt.__getters and mt.__getters[value] then
return mt.__getters[value](cls, value)
elseif mt.__getitem then
return mt.__getitem(cls, value)
elseif fallback then
return fallback
end
end
end
end

function setattr(cls, key, value)
local mt = getmetatable(cls)
if mt.__setters[key] then
mt.__setters[key](cls, value)
else
if mt.__setitem then
mt.__setitem(cls, key, value)
else
rawset(cls, key, value)
end
end
end


function copy(object, deep)
--copy object attributes
local c = {}
for k, v in pairs(object) do
if deep and is.table(v) then c[k] = copy(v, true)
else c[k] = v end
end
--copy metatable attributes
local mt = {}
local m = getmetatable(object)
if m then setmetatable(c, m) end

return c
end

function eval(input)
local f = load(input)
if f then
return f()
else
error('Syntax error occurred while parsing input: '..input)
end
end

function hash(input)
if is.func(input) then
input = tostring(input):match('function: (.*)')
else
local m = getmetatable(input)
if m and m.__hash then return m.__hash(input) end
end

local hsh
local mod = 2 ^ 64
if is.num(input) then
if input > 0 then hsh = -input * 2
elseif input < 0 then hsh = input * 2 - 1
else hsh = input end
elseif not is.str(input) then error("Can only hash functions, integers and strings")
else
hsh = string.byte(input[1]) * 2 ^ 7
for i, v in pairs(input) do hsh = (1000003 * hsh + string.byte(v)) % mod end
end
return hsh
end


function isin(sub, main)
local _is = false
local length, subLength
local mt = getmetatable(main)
if not mt or not mt.contains then
if is.str(main) then return Not.Nil(main:find(sub))
elseif is.table(main) then length = #main; subLength = 1
else length = 1; subLength = 1 end
for i=1, length do
if _is then break end
for j=0, subLength do
if requal(main[i + j], sub) then
_is = true
break
end
end
end
else
_is = main:contains(sub)
end
return _is
end

function isnotin(sub, main) return not isin(sub, main) end

function isinstance(klass, other)
local m = getmetatable(klass)
if not m or not m.__name then
if other and other.__name then
other = ''
elseif not is.str(other) then
other = type(other)
end
return type(klass) == other
else
if is.str(other) then other = {__name = other} end
end

local i, v
local to_check = {}
while m do
if m.__name == other.__name then
return true
else
for i, v in pairs(m.__bases) do to_check[#to_check + 1] = v end
i, m = next(to_check, i)
end
end
return false
end

function max(...)
local args
if is.table(...) then args = ... else args = {...} end
local mt = getmetatable(args)
if mt and mt.__name == 'set' then -- special case for set objects
args = args:values()
end
return math.max(unpack(args))
end

function min(...)
local args
if is.table(...) then args = ... else args = {...} end
local mt = getmetatable(args)
if mt and mt.__name == 'set' then -- special case for set objects
args = args:values()
end
return math.min(unpack(args))
end

function num(input)
if is.num(input) then return input else return tonumber(input) end
end


local _print = log or print
function print(...)
local strings = {}
for i, v in pairs({...}) do strings[#strings + 1] = str(v) end
_print(table.concat(strings, '\t'))
end

function pprint(tbl)
return print("\n{\n" .. _string_converters.traverseTable(tbl,{[tbl]=true},1, ',') .. "}")
end

function property(klass, name, getter, setter)
assert(klass and name and getter, 'Must provide a class, name and getter function')
klass.__getters[name] = getter
klass.__setters[name] = setter
end


function repr(input)
local m = getmetatable(input)
if m and m.__repr then return input:__repr()
else return tostring(input) end
end


function str(input)
local m = getmetatable(input)
if m then
local _m = getmetatable(m)
if m.__tostring then return tostring(input)
elseif _m and _m.__tostring then return _m.__tostring(input) end
elseif isType(input, 'number') or isType(input, 'bool') then return tostring(input)
elseif isType(input, 'nil') then return 'nil'
elseif isType(input, 'string') then return input
elseif isType(input, 'table') then return _string_converters.table2string(input) end
return repr(input)
end



function reversed(object)
if is.str(object) then return object:reverse() end
local result = list()
for i, v in pairs(object) do result:insert(1, v) end
return result
end

function sorted(object, key)
local sorter
local cp = copy(object)
if isType(key, 'function') then
sorter = function(v1, v2)
v1, v2 = key(v1), key(v2)
return v1 < v2
end
end
table.sort(cp, sorter)
return cp
end


function _string_converters.class_repr(cls)
local obj_name, value = 'class', tostring(cls)
if getmetatable(cls) and getmetatable(cls).__name then
obj_name = 'instance'
value = cls.__base_repr or tostring(getmetatable(cls))
end
return '<'..string.gsub(value, 'table:', cls.__name..' '..obj_name..' at')..'>'
end

function _string_converters.class_str(cls)
if list{'dict', 'list', 'set'}:contains(getmetatable(cls).__name) then
return _string_converters.table2string(cls)
else
return _string_converters.class_repr(cls)
end
end


function _string_converters.table2string(input)
local m = getmetatable(input)
local function idxstr(idx, val, custom_type)
if custom_type then return str(val)
elseif is.str(val) then val = '"'..val..'"'
else val = str(val) end
if is.str(idx) then idx = '"'..idx..'"'
else idx = str(idx) end
return string.format('%s: %s', idx, val)
end

local custom = m and m.__name and list{'list', 'set'}:contains(m.__name)
local count, all_int = 0, true
for i, v in pairs(input) do
count = count + 1
if not is.num(i) or i ~= count then
all_int = false
break
end
end
if count ~= #input then all_int = false end
custom = custom or all_int

local pre, suf = '{', '}'
if input == list(input) then  pre, suf = '[', ']' end
local s = pre
for i, v in pairs(input) do
if s ~= pre then s = s .. ', ' end
s = s .. idxstr(i, v, custom)
end
return s .. suf
end


function _string_converters.traverseTable(dataTable,tableRef,indent,delim)
delim = delim or ','
local output = ""
local indentStr = string.rep("\t",indent)

local isPrimitiveType = {string=true, number=true, boolean=true, ['function']=true, thread=true, userdata=true, ['nil']=true}
local typeSortOrder = {
['boolean']  = 1;
['number']   = 2;
['string']   = 3;
['function'] = 4;
['thread']   = 5;
['table']    = 6;
['userdata'] = 7;
['nil']      = 8;
}


local function isPrimitiveArray(array)
local max,n = 0,0
if array.isinstance and (array:isinstance(list) or array:isinstance(set)) then return true end
for k,v in pairs(array) do
if not (type(k) == 'number' and k > 0 and math.floor(k) == k) or not isPrimitiveType[type(v)] then
return false
end
max = k > max and k or max
n = n + 1
end
return n == max
end


local function formatValue(value)
if type(value) == 'string' then
return string.format('%q',value)
else
return tostring(value)
end
end


local function formatKey(key,seq)
if seq then return "" end
if type(key) == 'string' then
if key:match('^[%a_][%w_]-$') == key then -- key is variable name
return key .. " = "
else
return "[" .. string.format('%q',key) .. "] = "
end
else
return "[" .. tostring(key) .. "] = "
end
end

local keyList = {}
for k,v in pairs(dataTable) do
if isPrimitiveType[type(k)] then
keyList[#keyList + 1] = k
end
end
table.sort(keyList,function(a,b)
local ta,tb = type(dataTable[a]),type(dataTable[b])
if ta == tb then
if type(a) == 'number' and type(b) == 'number' then
return a < b
else
return tostring(a) < tostring(b)
end
else
return typeSortOrder[ta] < typeSortOrder[tb]
end
end)

local in_seq = false
local prev_key = 0

for i = 1,#keyList do
local key = keyList[i]
if type(key) == 'number' and key > 0 and key - 1 == prev_key then
prev_key = key
in_seq = true
else
in_seq = false
end

local value = dataTable[key]
if type(value) == 'table' then
if tableRef[value] == nil then -- prevent reference loops
tableRef[value] = true

local has_items = false
for k,v in pairs(value) do
if isPrimitiveType[type(k)] and (isPrimitiveType[type(v)] or type(v) == 'table') then
has_items = true
break
end
end

if has_items then -- table contains values
if isPrimitiveArray(value) then -- collapse primitive arrays
output = output .. indentStr .. formatKey(key,in_seq) .. "{"
local i = 1
for _, v in pairs(value) do
output = output .. formatValue(v)
if i < len(value) then
output = output .. ", "
end
i = i + 1
end
output = output .. "}"..delim.."\n"
else -- table is not primitive array
output = output
.. indentStr .. formatKey(key,in_seq) .. "{\n"
.. _string_converters.traverseTable(value,tableRef,indent+1, delim)
.. indentStr .. "}"..delim.."\n"
end
else -- table is empty
output = output .. indentStr .. formatKey(key,in_seq) .. "{}"..delim.."\n"
end

tableRef[value] = nil
end
elseif isPrimitiveType[type(value)] then
output = output .. indentStr .. formatKey(key,in_seq) .. formatValue(value) .. ""..delim.."\n"
end
end
return output
end



function all(iterable)
for k, v in pairs(iterable) do
if Not(v) then return false end
end
return true
end


function any(iterable)
for k, v in pairs(iterable) do
if is(v) then return true end
end
return false
end




local type_index = {
['str'] = 'string',
['num'] = 'number',
['bool'] = 'boolean',
['tbl'] = 'table',
['file'] = 'userdata',
['func'] = 'function'
}

function isType(object, ...)
local types = {...}
if #types == 1 then return type(object) == types[1] end
local is_type = false
for i, v in pairs(types) do
is_type = is_type or type(object) == (type_index[v] or v)
end
return is_type
end

function isNotType(object, ...)
return not isType(object, ...)
end


is = setmetatable({}, {
--check truthy
__call = function(s, object)
if object == nil or object == false or object == 0 then
return false
elseif isType(object, 'number', 'boolean', 'userdata', 'function') then
return true
elseif isType(object, 'string') then
return #object > 0
elseif isType(object, 'table') then
if object.__is then
return object:__is()
else
local size = #object
if size == 0 then
for i, v in pairs(object) do
size = size + 1
end
end
return size > 0
end
end
return false
end,
--check type
__index = function(s, value)
return function(v)
local s = type_index[value] or value
return isType(v, s:lower())
end
end
})

Not = setmetatable({}, {
--check falsy
__call = function(s, object) return not is(object) end,
--check type
__index = function(s, value)
return function(v) return not is[value](v) end
end
})

function requal(value1, value2)
local all_equal = type(value1) == type(value2)
if all_equal and not is.table(value1) then
return value1 == value2
elseif all_equal then
all_equal = len(value1) == len(value2)
else
return false
end

local l1, l2 = {}, {}
for i, v in pairs(value1) do
if is.num(v) then v = str(v) end
table.insert(l1, v)
end
for i, v in pairs(value2) do
if is.num(v) then v = str(v) end
table.insert(l2, v)
end

local function sorter(first, second)
if is.table(first) or isType(first, 'function') then  return false end
if type(first) ~= type(second) then return false end
return first < second
end
table.sort(l1, sorter)
table.sort(l2, sorter)
for i, v in pairs(l1) do
if not all_equal then return false end
if is.table(v) then
all_equal = requal(v, l2[i])
else
all_equal = type(v) == type(l2[i])
if all_equal then all_equal = v == l2[i] end
end
end
return all_equal
end



function count(value, input)
local total = 0
for i, v in pairs(input) do if v == value then total = total + 1 end end
return total
end

function div(x, y) return math.floor(x / y) end

function len(input)
if is.Nil(input) then return 0
elseif is.num(input) or is.Bool(input) then return 1
else
local total = 0
for i, v in pairs(input) do total = total + 1 end
return total
end
end

function round(num, places)
local value = num * 10^places
if value - math.floor(value) >= 0.5 then value = value + 1 end
return math.floor(value) / 10 ^ places
end

function sign(n)
if n == 0 then return 1
else return math.floor(n / math.abs(n)) end
end

function sum(object)
local total = 0
for i, v in pairs(object) do total = total + v end
return total
end

requests = {}

function requests.delete(url, args)
return requests.request("DELETE", url, args)
end

function requests.get(url, args)
return requests.request("GET", url, args)
end

function requests.post(url, args)
return requests.request("POST", url, args)
end

function requests.put(url, args)
return requests.request("PUT", url, args)
end

function requests.request(method, url, args)
local _req = args or {}

if is.table(url) then
_req = url
else
_req.url = url
end

_req.method = method
local request = Request(_req)

if request:verify() then
local cmd = request:build()
return request:send(cmd)
else
return "failed"
end
end

local function parse_data(lines, request, response)
local err_msg = 'error in '..request.method..' request: '
assert(isnotin('failed', lines[6]), err_msg..'Url does not exist')

if not response.status_code or num(response.status_code) == -1 then
for i, ln in pairs(lines) do
local code, reason = ln:match('HTTP request sent, awaiting response[^%d]*(%d+) (.*)')
local content_length, mime_type = ln:match('Length: (%d+) %[(.*)%]')
if code then response.status_code = code end
if reason then response.reason = reason end
if content_length then response.content_length = content_length end
if mime_type then response.mime_type = mime_type end
end
end
response.status_code = num(response.status_code)
response.ok = response.status_code < 400
end

local function urlencode(params)
if is.str(params) then return params end
local s = ''
if not params or next(params) == nil then return s end
for key, value in pairs(params) do
if is(s) then s = s..'&' end
if tostring(value) then s = s..tostring(key)..'='..tostring(value) end
end
return s
end

Request = class('Request')
function Request:__init(request)
for k, v in pairs(request) do
setattr(self, k, v)
end
self.headers = dict(self.headers or dict())
self.method = request.method or "GET"
self.url = request.url or request[1] or ''
self._response_fn = '_response.txt'
end

function Request:build()
local cmd = list{'wget', '--method', self.method:upper()}
if is(self.params) then
self.url = self.url .. '?' .. urlencode(self.params)
end
cmd:extend(self:_add_auth() or {})
cmd:extend(self:_add_data() or {})
cmd:extend(self:_add_headers() or {})
cmd:extend(self:_add_proxies() or {})
cmd:extend(self:_add_ssl() or {})
cmd:extend(self:_add_user_agent() or {})
cmd:extend{"'"..self.url.."'"}
cmd:extend{'--output-file', '-'}
cmd:extend{'--output-document', self._response_fn}
return cmd
end

function Request:send(cmd)
local response = Response(self)

try(function()
local lines = exe(cmd)

with(open(self._response_fn), function(f)
response.text = f:read('*a') end)

try(function() parse_data(lines, self, response) end)

end,

except(function(err)
print('Requesting '..self.url..' failed - ' .. str(err))
end),

function()
exe{'rm', self._response_fn}
end
)

return response
end

function Request:verify()
assert(requal(self.data, json.decode(json.encode(self.data))),'Incorrect json formatting')
assert(self.url:startswith('http'), 'Only http(s) urls are supported')
return true
end

function Request:_add_auth()
if is(self.auth) then
local usr = self.auth.user or self.auth[1]
local pwd = self.auth.password or self.auth[2]
return {'--http-user', usr, '--http-password', pwd}
end
end

function Request:_add_data()
if is(self.data) then
if Not.string(self.data) then
self.data = urlencode(self.data)
end
return {'--body-data', "'"..self.data.."'"}
end
end

function Request:_add_headers()
local cmd = list()
if is(self.headers) then
for k, v in pairs(self.headers) do
cmd:append("--header='"..k..': '..str(v).."'")
end
end
return cmd
end

function Request:_add_proxies()
if is(self.proxies) then
local usr, pwd
for k, v in pairs(self.proxies) do
if isin('@', v) then usr, pwd = unpack(v:split('//')[2]:split('@')[1]:split(':')) end
end
end
end

function Request:_add_ssl()
if not self.verify_ssl or (self.url:startswith('https') and self.verify_ssl) then
return {'--no-check-certificate'}
end
end

function Request:_add_user_agent()
if is(self.user_agent) then
return {'-U', self.user_agent}
end
end

Response = class('Response')
function Response:__init(request)
assert(request, 'Cannot create response with no request')
self.request = request or {}
self.method = self.request.method
self.url = self.request.url
self.status_code = -1
self.reason = ''
self.text = ''
self.encoding = 'utf-8'
self.mime_type = 'text/html'
self.headers = dict()
self.ok = false
end

function Response:__tostring()
return string.format('<Response [%d]>', self.status_code)
end

function Response:iter_lines()
local i, v
local lines = self.text:split('\n')
return function() i, v = next(lines, i) return v end
end

function Response:json()
return json.decode(self.text)
end

function Response:raise_for_status()
if self.status_code ~= 200 then error('error in '..self.method..' request: '..self.status_code) end
end

colors = {
aqua    = 65535,    -- 65535
black   = 0,        -- 0
blue    = 255,      -- 255
fuchsia = 16711935, -- 16711935
gray    = 8421504,  -- 8421504
green   = 32768,    -- 32768
lime    = 65280,    -- 65280
maroon  = 8388608,  -- 8388608
navy    = 128,      -- 128
olive   = 8421376,  -- 8421376
orange  = 16753920, -- 16753920
purple  = 8388736,  -- 8388736
red     = 16711680, -- 16711680
silver  = 12632256, -- 12632256
teal    = 32896,    -- 32896
yellow  = 16776960, -- 16776960
white   = 16777215  -- 16777215
}



Pixel = class('Pixel')

function Pixel:__init(x, y, color)
self.x = x
self.y = y
self.expected_color = color or colors.white
end

function Pixel:__add(position)
local x = self.x + (position.x or position[1] or 0)
local y = self.y + (position.y or position[2] or 0)
return Pixel(x, y, self.expected_color)
end

function Pixel:__sub(position)
local x = self.x - (position.x or position[1] or 0)
local y = self.y - (position.y or position[2] or 0)
return Pixel(x, y, self.expected_color)
end

function Pixel:__eq(pixel)
return self.x == pixel.x and self.y == pixel.y and self.expected_color == pixel.expected_color
end

function Pixel:__hash()
return self.x * 1000000000000 + self.y * 100000000 + self.expected_color
end

function Pixel:__tostring()
return string.format('<Pixel(%d, %d)>', self.x, self.y)
end

property(Pixel, 'color', function(self)
return getColor(self.x, self.y)
end)

function Pixel:color_changed()
local old_color = self.color
return function()
local current_color = self.color
if current_color ~= old_color then
old_color = current_color
return true
end
return false
end
end

function Pixel:visible()
return self.color == self.expected_color
end



Pixels = class('Pixels')

function Pixels:__init(pixels)
self.pixels = list()
self.expected_colors = list()
local pixel_set = set()
for i, pixel in pairs(pixels or {}) do
if not isinstance(pixel, Pixel) then
pixel = Pixel(pixel[1], pixel[2], pixel[3])
end
if not pixel_set:contains(pixel) then
pixel_set:add(pixel)
self.pixels:append(pixel)
self.expected_colors:append(pixel.expected_color)
end
end
end

function Pixels:__add(other)
local pixel_set = set(self.pixels)
local new_pixels = list()
for i, pixel in pairs(other.pixels) do
local pix = Pixel(pixel.x, pixel.y, pixel.expected_color)
if not pixel_set:contains(pix) then new_pixels:append(pix) end
end
return Pixels(self.pixels + new_pixels)
end

function Pixels:__sub(other)
local pixel_set = set(other.pixels)
local new_pixels = list()
for p in iter(self.pixels) do
if not pixel_set:contains(p) then new_pixels:append(p)  end
end
return Pixels(new_pixels)
end

function Pixels:__eq(other)
if len(self.pixels) ~= len(other.pixels) then return false end
for i, pixel in pairs(other.pixels) do
if pixel ~= self.pixels[i] then return false end
end
return true
end

function Pixels:__tostring()
return string.format('<Pixels(n=%d)>', len(self.pixels))
end

property(Pixels, 'colors', function(self)
local positions = list()
for p in iter(self.pixels) do positions:append({p.x, p.y}) end
return getColors(positions)
end)

function Pixels:visible()
return requal(self.colors, self.expected_colors)
end

function Pixels:count()
local colors = self.colors
local count = 0
for i, v in pairs(colors) do
if v == self.expected_colors[i] then count = count + 1 end
end
return count
end

local function n_colors_changed(pixels, n)
local old_colors = pixels.colors

return function()
local count = 0
local current_colors = pixels.colors
for i, color in pairs(current_colors) do
if old_colors[i] ~= color then
count = count + 1
end
end

local result = count >= (n or len(current_colors))

if result then
old_colors = current_colors
end

return result
end
end

function Pixels:any_colors_changed()
return n_colors_changed(self, 1)
end

function Pixels:all_colors_changed()
return n_colors_changed(self, len(self.pixels))
end

function Pixels:n_colors_changed(n)
return n_colors_changed(self, n)
end



Region = class('Region', 'Pixels')

function Region:__init(positions, color)
self.color = color or colors.white
local pixels = list()
local pixel_set = set()
for p in iter(positions) do
local pix = Pixel(p.x or p[1], p.y or p[2], self.color)
if not pixel_set:contains(pix) then
pixel_set:add(pix)
pixels:append(pix)
end
end
Pixels.__init(self, pixels)
end

function Region:__add(other)
assert(other:isinstance(Region), 'Can only add Region objects to other Region objects')
assert(other.color == self.color, 'Can only add Regions of the same color')
return Region(self.pixels + other.pixels, self.color)
end

function Region:__sub(other)
assert(other:isinstance(Region), 'Can only subtract Region objects from other Region objects')
assert(other.color == self.color, 'Can only subtract Regions of the same color')
return Region(set(self.pixels) - set(other.pixels), self.color)
end

function Region:__tostring()
return string.format('<Region(pixels=%d, color=%d)>', len(self.pixels), self.color)
end

property(Region, 'center', function(self)
local x, y = 0, 0
for p in iter(self.pixels) do x, y = x + p.x, y + p.y end
return Pixel(x / len(self.pixels), y / len(self.pixels), self.color)
end)



Ellipse = class('Ellipse', 'Region')

function Ellipse:__init(options)
self.x = options.x or 0
self.y = options.y or 0
self.width = options.width or 1
self.height =  options.height or 1
self.spacing = options.spacing or 1
local positions = list()
-- TODO: Ellipse creation
Region.__init(self, positions, options.color)
end

function Ellipse:__tostring()
return string.format('<Ellipse(%d, %d, width=%d, height=%d, spacing=%d, color=%d, pixels=%d)>',
self.x, self.y, self.width, self.height, self.spacing, self.color, len(self.pixels))
end



Rectangle = class('Rectangle', 'Region')

function Rectangle:__init(options)
self.x = options.x or 0
self.y = options.y or 0
self.width = options.width or 1
self.height =  options.height or 1
self.spacing = options.spacing or 1
local positions = list()
for i=self.x, self.x + self.width, self.spacing do
for j=self.y, self.y + self.height, self.spacing do
positions:append({i, j})
end
end
Region.__init(self, positions, options.color)
end

function Rectangle:__tostring()
return string.format('<Rectangle(%d, %d, width=%d, height=%d, spacing=%d, color=%d, pixels=%d)>',
self.x, self.y, self.width, self.height, self.spacing, self.color, len(self.pixels))
end



Triangle = class('Triangle', 'Region')

function Triangle:__init(options)
-- TODO: Triangle creation
local positions = list()
Region.__init(self, positions, options.color)
end

function Triangle:__tostring()
return string.format('<Triangle(n=%d, color=%d)>', len(self.pixels), self.color)
end


function str_add(s, other) return s .. other end

function str_call(s,i,j)
if isType(i, 'number') then
return string.sub(s, i, j or #s)
elseif isType(i, 'table') then
local t = {}
for k, v in ipairs(i) do t[k] = string.sub(s, v, v) end
return table.concat(t)
end
end

function str_index(s, i) end

function str_mul(s, other)
local t = {}
for i=1, other do t[i] = s end
return table.concat(t)
end

function str_pairs(s)
local function _iter(s, idx)
if idx < #s then return idx + 1, s[idx + 1] end
end
return _iter, s, 0
end

_string = {
endswith = function(s, value) return s(-#value, -1) == value end,

format = function(s, ...)
if Not.Nil(string.find(s, '{[^}]*}')) then
local args; local modified = ''; local stringified = '';
local index = 1; local length = 0; local pad = 0
if is.table(...) then args = ... else args = {...} end

local function formatter(prev, match)
-- replace match
if match == '' then
stringified = str(args[index])
elseif match:startswith(':') then
length = tonumber(match(2))
stringified = str(args[index])
else
for i, v in pairs(args) do if i == match then stringified = v end end
end
-- apply padding if any
pad = math.max(0, math.abs(length) - #stringified)
if length < 0 then modified = modified + prev + stringified + ' ' * pad
else modified = modified + prev + ' ' *  pad + stringified end
index = index + 1
length = 0
end

s:gsub('(.-){([^}]*)}', formatter)
return modified
else return string.format(s, ...) end
end,

join = function(s, other) return table.concat(other, s) end,

replace = function(s, sub, rep, limit)
local _s, n = string.gsub(s, sub, rep, limit) return _s end,

split = function(s, delim)
local i = 1
local idx = 1
local values = {}

while i <= #s do
if is.Nil(delim) then values[i] = s[i]; i = i + 1
else
if s(i, i + #delim - 1) == delim then idx = idx + 1; i = i + #delim - 1
else
if is.Nil(values[idx]) then values[idx] = '' end
values[idx] = values[idx] .. s[i]
end
i = i + 1
end
end
for i, v in pairs(values) do if is.Nil(v) then values[i] = '' end end
return list(values)
end,

startswith = function(s, value) return s(1, #value) == value end,

strip = function(s, remove)
local start=1
local _end = #s
for i=1, #s do if isnotin(s[i], remove) then start = i break end end
for i=#s, start, -1 do if isnotin(s[i], remove) then _end = i break end end
return s(start, _end)
end
}


getmetatable('').__add = str_add
getmetatable('').__call = str_call
getmetatable('').__ipairs = str_pairs
getmetatable('').__mul = str_mul
getmetatable('').__pairs = str_pairs
getmetatable('').__index = function(s, i)
if isType(i, 'number') then
if i < 0 then i = #s + 1 + i end
return string.sub(s, i, i)
else
return _string[i] or string[i]
end
end


function try(f, _except, finally)
_except = _except or function() end
local success, result = xpcall(f, _except)
if finally then finally() end
if not success and result then error(tostring(result)) end
return result
end


function except(types, f)
if isType(types, 'table') then
local mt = getmetatable(types)
if mt and types.type then types = {types} end
elseif isType(types, 'string') then
types = {types}
end

if not types and not f then
types, f = {'.*'}, function() end
elseif not f then
if isType(types, 'function') then
types, f = {'.*'}, types
end
end
types = types or {'.*'}

return function(err)
for i, _type in pairs(types) do
if isType(_type, 'table') then
_type = _type.type or _type.__name or getmetatable(_type).__name
end
if string.find(tostring(err), _type) then
local success, result = pcall(f or function() end, err)
if not success then
return tostring(err)..
'\n\nDuring handling of the above exception, another exception occurred:\n\n'
..result
elseif result or (success and not result) then
return result
end
end
end
return err
end
end


function with(context, _do)
local ctx = context()
local success, result = coroutine.resume(ctx)
if success then
local error_type, error_message
try(
function() _do(result) end,
except(function(err)
if err.type then
error_type = err.type
error_message = err.message
else
error_type = 'Exception'
error_message = err
end
end),
function() context:__exit(error_type, error_message) end
)
end
coroutine.resume(ctx)
end


function yield(...) coroutine.yield(...) end


function contextmanager(f)
return function(...)
local Context = ContextManager(...)
Context.__enter = function(self)
return f(unpack(self.args))
end
return Context
end
end


function open(name, mode)
if rootDir then name = pathJoin(rootDir(), name) end
local f = assert(io.open(name, mode or 'r'))
yield(f)
f:close()
end



function run_and_close(name, close_after)
if close_after ~= false then close_after = true end
if appState(name) ~= "NOT RUNNING" then appKill(name) end
appRun(name)
yield()
if close_after then appKill(name) end
end
function run_if_closed(name)
local run_kill = false
if appState(name) ~= "ACTIVE" then
run_kill = true
end

if run_kill then appRun(name) end
yield()
if run_kill then appKill(name) end

end



function suppress(...)
local errors = {... or '.*'}
local Context = ContextManager()

Context.__exit = function(self, _type, value)
local e = except(errors)(_type or value)
if e then error(e) end
end

return Context
end


function time_ensured(t)
local start = os.time()
yield()
sleep(max(0, t - (os.time() - start)))
end


function time_padded(t_before, t_after)
sleep(t_before)
yield()
sleep(t_after or t_before)
end


ContextManager = class("ContextManager")


function ContextManager:__init(...)
self.args = {...}
end


function ContextManager:__call()
return coroutine.create(function()
local success, result
success, result = pcall(self.__enter, self, unpack(self.args))
if success then
coroutine.yield(result)
else
error(result)
end
end)
end

function ContextManager:__enter()
return self
end

function ContextManager:__exit(_type, value)
if _type then
value = Exception(_type, value).message
else
value = _type or value
end
if value then error(value) end
end


Exception = class('Exception')

function Exception:__init(_type, message)
self.type = _type
self.message = message or ''
end

function Exception:__tostring()
return Exception.add_traceback('<'..self.type..'> '..self.message)
end

function Exception:__repr()
return tostring(self)
end


function Exception:__call(message)
return Exception(self.type, message)
end

function Exception.add_traceback(s, force)
local start = list()
local traceback = debug.traceback()
if traceback then
local lines = traceback:split('\n')
local count = 0
for i, ln in pairs(lines) do
if ln:startswith('\t[C]') then
count = count + 1
start:append(i)
end
end
if not lines:contains("\t[C]: in function 'error'") and not force then return s end
if not force then lines = lines(start[-2]) else lines = lines(2) end
s = s..'\nstack traceback:\n'..table.concat(lines, '\n')
end
return s
end


AssertionError = Exception('AssertionError')
IOError = Exception('IOError')
KeyError = Exception('KeyError')
OSError = Exception('OSError')
TypeError = Exception('TypeError')
ValueError = Exception('ValueError')

open = contextmanager(open)
run_and_close = contextmanager(run_and_close)
run_if_closed = contextmanager(run_if_closed)
time_ensured = contextmanager(time_ensured)
time_padded = contextmanager(time_padded)
json = {}

local encode

local escape_char_map = {
[ "\\" ] = "\\\\",
[ "\"" ] = "\\\"",
[ "\b" ] = "\\b",
[ "\f" ] = "\\f",
[ "\n" ] = "\\n",
[ "\r" ] = "\\r",
[ "\t" ] = "\\t",
}

local escape_char_map_inv = { [ "\\/" ] = "/" }
for k, v in pairs(escape_char_map) do
escape_char_map_inv[v] = k
end


local function escape_char(c)
return escape_char_map[c] or string.format("\\u%04x", c:byte())
end


local function encode_nil(val)
return "null"
end


local function encode_table(val, stack)
local res = {}
stack = stack or {}

-- Circular reference?
if stack[val] then error("circular reference") end

stack[val] = true

if val[1] ~= nil or next(val) == nil then
-- Treat as array -- check keys are valid and it is not sparse
local n = 0
for k in pairs(val) do
if type(k) ~= "number" then
error("invalid table: mixed or invalid key types")
end
n = n + 1
end
if n ~= #val then
error("invalid table: sparse array")
end
-- Encode
for i, v in ipairs(val) do
table.insert(res, encode(v, stack))
end
stack[val] = nil
return "[" .. table.concat(res, ",") .. "]"

else
-- Treat as an object
for k, v in pairs(val) do
if type(k) ~= "string" then
error("invalid table: mixed or invalid key types")
end
table.insert(res, encode(k, stack) .. ":" .. encode(v, stack))
end
stack[val] = nil
return "{" .. table.concat(res, ",") .. "}"
end
end


local function encode_string(val)
return '"' .. val:gsub('[%z\1-\31\\"]', escape_char) .. '"'
end


local function encode_number(val)
-- Check for NaN, -inf and inf
if val ~= val or val <= -math.huge or val >= math.huge then
error("unexpected number value '" .. tostring(val) .. "'")
end
return string.format("%.14g", val)
end


local type_func_map = {
[ "nil"     ] = encode_nil,
[ "table"   ] = encode_table,
[ "string"  ] = encode_string,
[ "number"  ] = encode_number,
[ "boolean" ] = tostring,
}


encode = function(val, stack)
local t = type(val)
local f = type_func_map[t]
if f then
return f(val, stack)
end
error("unexpected type '" .. t .. "'")
end


function json.encode(val)
return ( encode(val) )
end


local parse

local function create_set(...)
local res = {}
for i = 1, select("#", ...) do
res[ select(i, ...) ] = true
end
return res
end

local space_chars   = create_set(" ", "\t", "\r", "\n")
local delim_chars   = create_set(" ", "\t", "\r", "\n", "]", "}", ",")
local escape_chars  = create_set("\\", "/", '"', "b", "f", "n", "r", "t", "u")
local literals      = create_set("true", "false", "null")

local literal_map = {
[ "true"  ] = true,
[ "false" ] = false,
[ "null"  ] = nil,
}


local function next_char(str, idx, set, negate)
for i = idx, #str do
if set[str:sub(i, i)] ~= negate then
return i
end
end
return #str + 1
end


local function decode_error(str, idx, msg)
local line_count = 1
local col_count = 1
for i = 1, idx - 1 do
col_count = col_count + 1
if str:sub(i, i) == "\n" then
line_count = line_count + 1
col_count = 1
end
end
error( string.format("%s at line %d col %d", msg, line_count, col_count) )
end


local function codepoint_to_utf8(n)
-- http://scripts.sil.org/cms/scripts/page.php?site_id=nrsi&id=iws-appendixa
local f = math.floor
if n <= 0x7f then
return string.char(n)
elseif n <= 0x7ff then
return string.char(f(n / 64) + 192, n % 64 + 128)
elseif n <= 0xffff then
return string.char(f(n / 4096) + 224, f(n % 4096 / 64) + 128, n % 64 + 128)
elseif n <= 0x10ffff then
return string.char(f(n / 262144) + 240, f(n % 262144 / 4096) + 128,
f(n % 4096 / 64) + 128, n % 64 + 128)
end
error( string.format("invalid unicode codepoint '%x'", n) )
end


local function parse_unicode_escape(s)
local n1 = tonumber( s:sub(3, 6),  16 )
local n2 = tonumber( s:sub(9, 12), 16 )
-- Surrogate pair?
if n2 then
return codepoint_to_utf8((n1 - 0xd800) * 0x400 + (n2 - 0xdc00) + 0x10000)
else
return codepoint_to_utf8(n1)
end
end


local function parse_string(str, i)
local has_unicode_escape = false
local has_surrogate_escape = false
local has_escape = false
local last
for j = i + 1, #str do
local x = str:byte(j)

if x < 32 then
decode_error(str, j, "control character in string")
end

if last == 92 then -- "\\" (escape char)
if x == 117 then -- "u" (unicode escape sequence)
local hex = str:sub(j + 1, j + 5)
if not hex:find("%x%x%x%x") then
decode_error(str, j, "invalid unicode escape in string")
end
if hex:find("^[dD][89aAbB]") then
has_surrogate_escape = true
else
has_unicode_escape = true
end
else
local c = string.char(x)
if not escape_chars[c] then
decode_error(str, j, "invalid escape char '" .. c .. "' in string")
end
has_escape = true
end
last = nil

elseif x == 34 then -- '"' (end of string)
local s = str:sub(i + 1, j - 1)
if has_surrogate_escape then
s = s:gsub("\\u[dD][89aAbB]..\\u....", parse_unicode_escape)
end
if has_unicode_escape then
s = s:gsub("\\u....", parse_unicode_escape)
end
if has_escape then
s = s:gsub("\\.", escape_char_map_inv)
end
return s, j + 1

else
last = x
end
end
decode_error(str, i, "expected closing quote for string")
end


local function parse_number(str, i)
local x = next_char(str, i, delim_chars)
local s = str:sub(i, x - 1)
local n = tonumber(s)
if not n then
decode_error(str, i, "invalid number '" .. s .. "'")
end
return n, x
end


local function parse_literal(str, i)
local x = next_char(str, i, delim_chars)
local word = str:sub(i, x - 1)
if not literals[word] then
decode_error(str, i, "invalid literal '" .. word .. "'")
end
return literal_map[word], x
end


local function parse_array(str, i)
local res = {}
local n = 1
i = i + 1
while 1 do
local x
i = next_char(str, i, space_chars, true)
-- Empty / end of array?
if str:sub(i, i) == "]" then
i = i + 1
break
end
-- Read token
x, i = parse(str, i)
res[n] = x
n = n + 1
-- Next token
i = next_char(str, i, space_chars, true)
local chr = str:sub(i, i)
i = i + 1
if chr == "]" then break end
if chr ~= "," then decode_error(str, i, "expected ']' or ','") end
end
return res, i
end


local function parse_object(str, i)
local res = {}
i = i + 1
while 1 do
local key, val
i = next_char(str, i, space_chars, true)
-- Empty / end of object?
if str:sub(i, i) == "}" then
i = i + 1
break
end
-- Read key
if str:sub(i, i) ~= '"' then
decode_error(str, i, "expected string for key")
end
key, i = parse(str, i)
-- Read ':' delimiter
i = next_char(str, i, space_chars, true)
if str:sub(i, i) ~= ":" then
decode_error(str, i, "expected ':' after key")
end
i = next_char(str, i + 1, space_chars, true)
-- Read value
val, i = parse(str, i)
-- Set
res[key] = val
-- Next token
i = next_char(str, i, space_chars, true)
local chr = str:sub(i, i)
i = i + 1
if chr == "}" then break end
if chr ~= "," then decode_error(str, i, "expected '}' or ','") end
end
return res, i
end


local char_func_map = {
[ '"' ] = parse_string,
[ "0" ] = parse_number,
[ "1" ] = parse_number,
[ "2" ] = parse_number,
[ "3" ] = parse_number,
[ "4" ] = parse_number,
[ "5" ] = parse_number,
[ "6" ] = parse_number,
[ "7" ] = parse_number,
[ "8" ] = parse_number,
[ "9" ] = parse_number,
[ "-" ] = parse_number,
[ "t" ] = parse_literal,
[ "f" ] = parse_literal,
[ "n" ] = parse_literal,
[ "[" ] = parse_array,
[ "{" ] = parse_object,
}


parse = function(str, idx)
local chr = str:sub(idx, idx)
local f = char_func_map[chr]
if f then
return f(str, idx)
end
decode_error(str, idx, "unexpected character '" .. chr .. "'")
end


function json.decode(str)
if type(str) ~= "string" then
error("expected argument of type string, got " .. type(str))
end
return ( parse(str, next_char(str, 1, space_chars, true)) )
end

local popen = io.popen

local _count               = {success=0, failed=0, skipped=0, errors=0}
local _errors              = {}
local _fixtures            = {}
local _test_utils          = {}
local _tests               = {}
local _tests_duration      = 0

local _current_fixtures    = {}
_current_fixtures.func     = {}
_current_fixtures.group    = {}
_current_fixtures.module   = {}

local _finalizers    = {}
_finalizers.func     = {}
_finalizers.group    = {}
_finalizers.module   = {}


local _lines_of_this_file = {}
local _ansi_keys = {
reset      = 0,
bright     = 1,
dim        = 2,
red       = 31,
green     = 32,
yellow    = 33,
blue      = 34,
magenta   = 35,
cyan      = 36,
white     = 37,
}
local _concatenated = ''
if rootDir then
io.write = function(s)
_concatenated = _concatenated..s
if _concatenated:match('\n') then print(_concatenated); _concatenated = '' end
end
end


local function format_ne(msg, v1, v2)
msg = msg or ''
return msg..string.format(' ==> %s != %s', str(v1 or ''), str(v2 or ''))
end

local function format_ge(msg, more, less)
msg = msg or ''
return msg..string.format(' ==> %s is not greater than %s', tostring(more), tostring(less))
end


function assertEqual(v1, v2, msg) assert(v1 == v2, format_ne(msg, v1, v2)) end

function assertNotEqual(v1, v2, msg) assert(v1 ~= v2, format_ne(msg, v1, v2)) end

function assertRequal(v1, v2, msg) assert(requal(v1, v2), format_ne(msg, v1, v2)) end

function assertNotRequal(v1, v2, msg) assert(not requal(v1, v2), format_ne(msg, v1, v2)) end

function assertLessThan(less, more, msg) assert(less < more, format_ge(msg, more, less)) end

function assertMoreThan(more, less, msg) assert(more > less, format_ge(msg, more, less)) end

function assertLessThanEqual(less, more, msg) assert(less <= more, format_ge(msg, more, less)) end

function assertMoreThanEqual(more, less, msg) assert(more >= less, format_ge(msg, more, less)) end

function assertRaises(exception, func, msg)
local success, result = pcall(func)
if isNotType(exception, 'string') then
exception = exception.type
end
assert(not success, 'No exception raised: '..msg)
assert(string.find(result or '', tostring(exception)), 'Incorrect error raised: '..msg)
end


function describe(description, ...)
local test_functions = {...}
table.insert(_tests, {description=description, func=function()
for i, test_funcs in pairs(test_functions) do
if test_funcs.func ~= nil then test_funcs = {test_funcs} end
for _, test_obj in pairs(test_funcs) do
local _, err = pcall(test_obj.func, test_obj.f, description)
_test_utils.write_test_result(err, description, test_obj.description)
_test_utils.destroy_all_fixtures('func', description, test_obj.description)
end
end
end})
end


function it(description, f)
return {description=description, f=f, func=function(fn, group_description)
local arg_table = _test_utils.setup_teardown_test(
function(err) end, _test_utils.create_arg_table, fn, description
)
if type(arg_table) == 'string' then return {msg=arg_table, args={}} end
local status, err = pcall(fn, unpack(arg_table))
if not status then return {msg=err, args=arg_table} end
end}
end


function fixture(name, scope, f)
if f then
_fixtures[name] = {func=f, scope=scope}
else
_fixtures[name] = {func=scope, scope='func'}
end
end


function parametrize(names, parameters, f)
local fields = {}
names:gsub("([^,]+)", function(c) fields[#fields+1] = c end)
local arg_names = _test_utils.get_arg_names(f.f)
local _args = {}
for _, k in pairs(arg_names) do
local in_fields = false
for _, n in pairs(fields) do
if k:gsub(' *', '') == n:gsub(' *', '') then in_fields = true; break end
end
if not in_fields then table.insert(_args, k) end
end
local args_string = table.concat(_args, ',')
local args_inner = args_string
if args_inner ~= '' then args_inner = ', '..args_inner end
local parametrized = {}
for _, params in pairs(parameters) do
if type(params) ~= 'table' then params = {params} end
local code = 'function(%s) f(unpack(params)%s) end'
local pfunc = load('return '..code:format(args_string, args_inner), nil, "t", {
f=f.f, params=params, unpack=unpack
})()
table.insert(parametrized, {description=f.description, func=f.func, f=pfunc})
end
return parametrized
end


function run_tests()
_test_utils.write_began_tests()

local begin_time = _test_utils.get_system_time()
for _, test_obj in pairs(_tests) do
_test_utils.write_test_description(test_obj.description)

test_obj.func()
_test_utils.destroy_all_fixtures('group', test_obj.description)

io.write('\n')
end
_test_utils.destroy_all_fixtures('module')
_tests_duration = _test_utils.get_system_time() - begin_time

local exit_code = math.min(1, _count.failed + _count.errors)
_test_utils.write_completed_tests()
_test_utils.write_errors()
_test_utils.reset_internals()
return exit_code
end






function _test_utils.ansi(c)
if rootDir then return end
if type(c) == 'string' then c = _ansi_keys[c] end
io.write(string.char(27)..'['..tostring(c)..'m')
end

function _test_utils.create_arg_table(f, desc)
local arg_table = {}
local params = _test_utils.get_arg_names(f)
for i, v in pairs(params) do
if v == 'request' then
arg_table[i] = {addfinalizer=function(f) table.insert(_finalizers.func, {f=f, name=v}) end}
elseif v == 'monkeypatch' then
arg_table[i] = {setattr=function(o, k, v) _test_utils.setattr(_finalizers.func, desc, o, k, v) end}
else
arg_table[i] = _test_utils.create_fixture(v)
end
end
return arg_table
end

function _test_utils.create_fixture(name)
local fix = _fixtures[name]
if not fix then error('Fixture "'..name..'" is not defined') end
-- return fixture if exists
for fixt_name, fixt in pairs(_current_fixtures[fix.scope]) do
if name == fixt_name then
return fixt.value
end
end
-- create fixture
local arg_table = _test_utils.get_fixture_args(fix.func, fix.scope, name)
local status, result = pcall(fix.func, unpack(arg_table))
if not status then
_current_fixtures[fix.scope][name] = {value=nil}
error(string.format('Error setting up fixture %s: %s', name, result))
end
_current_fixtures[fix.scope][name] = {value=result}
return result
end

function _test_utils.destroy_all_fixtures(scope, desc, func_name)
_test_utils.setup_teardown_test(

function(err)
_test_utils.insert_error({msg=err, args={}}, func_name or '', desc or 'Teardown')
end,

function()
for name, fixtures in pairs(_current_fixtures[scope]) do
_current_fixtures[scope][name] = nil
end
for _, final in pairs(_finalizers[scope]) do
local status, result = pcall(final.f)
if not status then error(string.format('Error tearing down fixture %s: %s', final.name, result)) end
end
_finalizers[scope] = {}
end
)
end

function _test_utils.get_arg_names(f)
local co = coroutine.create(f)
local params = {}

debug.sethook(co, function()
local i, k = 1, debug.getlocal(co, 2, 1)
while k do
if k ~= "(*temporary)" then table.insert(params, k) end
i = i+1
k = debug.getlocal(co, 2, i)
end
error("~~end~~")
end, "c")

local res, err = coroutine.resume(co)
if res then
error("The function provided defies the laws of the universe.", 2)
elseif string.sub(tostring(err), -7) ~= "~~end~~" then
error("The function failed with the error: "..tostring(err), 2)
end

return params

end

function _test_utils.get_fixture_args(func, scope, fix_name)
local arg_table = {}

local params = _test_utils.get_arg_names(func)
for i, name in pairs(params) do
if name == 'request' then
arg_table[i] = {addfinalizer=function(f) table.insert(_finalizers[scope], {f=f, name=fix_name}) end}
elseif name == 'monkeypatch' then
arg_table[i] = {setattr=function(o, k, v) _test_utils.setattr(_finalizers[scope], fix_name, o, k, v) end}
else
arg_table[i] = _test_utils.create_fixture(name)
end
end
return arg_table
end

function _test_utils.get_line_stripped(lineno)
if #_lines_of_this_file == 0 then
for l in io.lines(debug.getinfo(1, 'S').short_src) do
_lines_of_this_file[#_lines_of_this_file + 1] = l
end
end
return _lines_of_this_file[lineno]:gsub('[ \t]*', '')
end

function _test_utils.get_system_time()
local _time = os.time()
pcall(function()
local _f = assert(io.popen('date +%s%N'))
_time = tonumber(_f:read()) / 1000000000
assert(_f:close())
end)
return _time
end

function _test_utils.get_terminal_width(default_width)
local width = default_width
pcall(function()
local _f = assert(io.popen('tput cols'))
width = tonumber(_f:read()) or default_width
assert(_f:close())
end)
return width
end

function _test_utils.insert_error(err, test_desc, group_desc)
local file_location = err.msg:match('(.*:%d+):.*')
local line_no = err.msg:match('.*:(%d+):.*')
local message = err.msg:match('.*:%d+: (.*)')
table.insert(_errors, {
fixtures   = err.args,
group_name = group_desc,
test_name  = test_desc,
message    = message,
location   = file_location,
line_no    = line_no
})
end

function _test_utils.reset_internals()
_count                     = {success=0, failed=0, skipped=0, errors=0}
_current_fixtures.func     = {}
_current_fixtures.group    = {}
_current_fixtures.module   = {}
_errors                    = {}
_fixtures                  = {}
_tests                     = {}
_tests_duration            = 0

end

function _test_utils.setattr(finalizers, name, obj, key, value)
local current_value, finalize
if value == nil then
current_value = _G[obj]
finalize = function() _G[obj] = current_value end
_G[obj] = key
else
current_value = obj[key]
finalize = function() obj[key] = current_value end
obj[key] = value
end
table.insert(finalizers, {f=finalize, name=name})
end

function _test_utils.setup_teardown_test(on_complete, f, ...)
local status, result = pcall(f, ...)
if not status then
io.write('E')
_count.errors = _count.errors + 1
if result then
on_complete(result)
end
end
return result
end

local _terminal_width = _test_utils.get_terminal_width(50)

function _test_utils.write_equals_padded(msg)
local width = _terminal_width - string.len(msg) - 8
for i=1, width/2 do io.write('=') end
io.write('    '..msg..'    ')
for i=1, width/2  do io.write('=') end
io.write('\n')
end

function _test_utils.write_began_tests()
_test_utils.ansi('bright')
_test_utils.write_equals_padded('test session starts')
io.write('testing: ')
_test_utils.ansi('reset')
_test_utils.ansi('white')
io.write(debug.getinfo(1, 'S').short_src..'\n')
_test_utils.ansi('reset')
io.write('\n')
end

function _test_utils.write_completed_tests()
io.write('\n')
local message = ''
if _count.failed == 0 then
if _count.success > 0 then
_test_utils.ansi('bright')
_test_utils.ansi('green')
else
_test_utils.ansi('yellow')
end
else
_test_utils.ansi('bright')
_test_utils.ansi('red')
message = message.._count.failed..' failed'
if _count.success > 0 then message = message..', ' end
end
if _count.success > 0 then message = message.._count.success..' passed' end
if _count.skipped > 0 then message = message..', '.._count.skipped..' skipped' end
if _count.errors > 0 then message = message..', '.._count.errors..' error' end
if _count.success + _count.skipped + _count.errors == 0 then
message = 'No tests found'
else
message = message..string.format(' in %.2f seconds', _tests_duration)
end
_test_utils.write_equals_padded(message)
_test_utils.ansi('reset')
_test_utils.ansi('reset')
io.write('\n')
end

function _test_utils.write_test_description(description)
io.write('\t'..description..': ')
end

function _test_utils.write_errors()
if #_errors > 0 then
io.write('Collected errors:\n\n')
for _, err in pairs(_errors) do
_test_utils.ansi('bright')
_test_utils.ansi('red')
io.write(string.format('%s - %s ', err.group_name, err.test_name))
_test_utils.ansi('reset')

_test_utils.ansi('yellow')
io.write(string.format('@ %s', err.line_no))
_test_utils.ansi('reset')

local tab_count = 1
local function _tab(n) tab_count = tab_count + (n or 0); return string.rep('\t', tab_count-1) end
io.write('\n'.._tab(1)..'|--> ')

_test_utils.ansi('cyan')
io.write(string.format('%s\n', err.location))
_test_utils.ansi('reset')

io.write(string.format(_tab(1)..'%s\n', err.message))

io.write('\n')
end
end
end

function _test_utils.write_test_result(err, group_desc, test_desc)
if err == nil then
io.write('.')
_count.success = _count.success + 1
elseif err.msg ~= nil then
io.write('F')
_count.failed = _count.failed + 1
_test_utils.insert_error(err, test_desc, group_desc)
end
end


local function _getType(name)
return exe(string.format(
'if test -f "%s"; then echo "FILE"; elif test -d "%s"; then echo "DIR"; else echo "INVALID"; fi',
name, name))
end

function get_cwd(file)
return exe('pwd')
end

function exe(cmd, split_output)
if is.Nil(split_output) then split_output = true end
if isNotType(cmd, 'string') then cmd = table.concat(cmd, ' ') end

if rootDir then cmd = 'cd '..rootDir()..'; '..cmd end

local f = assert(io.popen(cmd, 'r'))
local data = readLines(f)
local success, status, code = f:close()
if split_output then
if #data == 1 then data = data[1] end
else
data = table.concat(data, '\n')
end

if code ~= 0 then
return data, status, code
else
return data or ''
end
end

function fcopy(src, dest, overwrite)
if is.Nil(overwrite) then overwrite = true end
local cmd = list{'cp'}
if isDir(src) then cmd:append('-R') end
if not overwrite then cmd:append('-n') end
cmd:extend{src, dest}
exe(cmd)
end

function find(name, starting_directory)
local _type = 'f'
if is.table(name) then
starting_directory = name.start
if name.file or name.f then
name = name.file or name.f
_type = 'f'
elseif name.dir or name.d then
name = name.dir or name.d
_type = 'd'
else
error('Incorrect table arguments ("file"/"f" or "dir"/"d" or "start")')
end
end
return exe({'find', starting_directory or '.', '-type', _type, '-name', name})
end

function isDir(name) return _getType(name) == 'DIR' end

function isFile(name) return _getType(name) == 'FILE' end

function listdir(dirname) return sorted(exe{'ls', dirname}) end

function pathExists(path) return _getType(path) ~= 'INVALID' end

function pathJoin(...)
local values
if is.table(...) then values = ... else values = {...} end
local s = string.gsub(table.concat(values, '/'), '/+', '/')
return s
end

function readLine(f, lineNumber)
local lines = readLines(f)
return lines[lineNumber]
end

function readLines(f)
local lines = list()
local function read(fle) for line in fle:lines() do lines:append(line) end end
if is.str(f) then with(open(f, 'r'), read) else read(f) end
if lines[#lines] == '' then lines[#lines] = nil end
return lines
end

function sizeof(name)
local result = exe(string.format('du %s', name))
local size = 0
for a in string.gmatch(result, "[0-9]*") do size = num(a); break end
return size
end

function sleep(seconds)
if seconds <= 0.01 then
local current = os.clock()
while os.clock() - current < seconds do end
return
end
local time_ns = os.time()
while (os.time() - time_ns) < seconds do
io.popen('sleep 0.001'):close()
end
end

function writeLine(line, lineNumber, filename)
local lines = readLines(filename)
lines[lineNumber] = line
writeLines(lines, filename, 'w')
end

function writeLines(lines, filename, mode)
local function write(f)
for i, v in pairs(lines) do f:write(v .. '\n') end
end
with(open(filename, mode or 'w'), write)
end


function os.time()
local f = io.popen('date +%s%N')
local t = tonumber(f:read()) / 1000000000
f:close()
return t
end


local function namedRequality(name)
return function(me, other)
local mt = getmetatable(other)
if mt and mt.__name == name then
return requal(me, other)
end
return false
end
end

dict = class('dict')

function dict:__init(dct) self:update(dct or {}) end

function dict:__add(other)
local result = dict(self)
result:update(other)
return result
end

function dict:__call(...)
assert(is.Nil(...), 'Dict can only be called in a for-loop')
local key, value
return function()
key, value =  next(self, key, value)
return key
end
end

function dict:__eq(other) return namedRequality('dict')(self, other) end

function dict:__setitem(key, value) self:set(key, value) end

function dict:__ipairs() return self:__pairs() end

function dict:__len() return 0 end

function dict:__pairs()
local function iter(value, key)
key, value =  next(self, key, value)
return key, value
end
return iter, self, nil
end

function dict:clear() for k, v in pairs(self) do self:set(k, nil) end end

function dict:contains(key) return Not.Nil(rawget(self, key)) end

function dict:get(key, default) return rawget(self, key) or default end

function dict:items() return pairs(self) end

function dict:keys()
local ks = list()
for k in self() do ks:append(k) end
return sorted(ks)
end

function dict:pop(key, default)
if key then
result = rawget(self, key) or default
rawset(self, key, nil)
return result
else
local k, v = pairs(self)(self)
rawset(self, k, nil)
return v
end
end

function dict:set(key, value) rawset(self, key, value) end

function dict:update(other) for k, v in pairs(other) do self:set(k, v) end end

function dict:values()
local vs = list()
for k, v in pairs(self) do vs:append(v) end
return vs
end


list = class('list')


function list:__init(lst)
if is.table(lst) then self:extend(lst) end
end

function list:__add(other) local new = list(self); new:extend(other); return new end

function list:__call(start, _end, step)
local key, value
local slice = list()

if is.Nil(start or _end or step) then  -- no arguements -> for loop
return function()
key, value =  next(self, key, value)
return value
end
else -- arguments -> slice
_end = _end or #self
if _end < 0 and not step then _end = #self + 1 + _end end
if is.table(start) then for i, v in pairs(start) do slice:append(self[v]) end
else for i=start, _end, step or 1 do slice:append(self[i]) end end
return slice
end
end

function list:__eq(other) return namedRequality('list')(self, other) end

function list:__len() return len(self) end

function list:__getitem(value)
if is.str(value) then return rawget(list, value)
else
if sign(value) < 0 then value = #self + 1 + value end
return rawget(self, value) end
end

function list:__mul(n)
local result = list()
for i=1, n do result:extend(self) end
return result
end

function list:append(value) rawset(self, #self + 1, value) end

function list:clear() for k, _ in pairs(self) do rawset(self, k, nil) end end

function list:contains(value)
for i, v in pairs(self) do if requal(v, value) then return true end end
return false
end

function list:extend(values) for i, v in pairs(values) do self:append(v) end end

function list:index(value) for i, v in pairs(self) do if requal(v, value) then return i end end end

function list:insert(index, value)
for i=#self, index, -1 do rawset(self, i + 1, rawget(self, i)) end
rawset(self, index, value)
end

function list:pop(index)
local value = rawget(self, index or 1)
for i=index or 1, #self do rawset(self, i, rawget(self, i + 1)) end
return value
end

function list:remove(value) local _ = self:pop(self:index(value)) end


set = class('set')

function set:__init(s)
self:update(s or {})
end

function set:__add(other)
local new = set(self)
new:update(other)
return new
end

function set:__call(...)
assert(is.Nil(...), 'Set can only be called in a for-loop')
local key, value
return function()
key, value =  next(self, key, value)
return value
end
end

function set:__eq(other) return namedRequality('set')(self, other) end

function set:__len() return 0 end

function set:__pairs()
local function iter(value, key)
return next(self, key, value)
end
return iter, self, nil
end

function set:__sub(other) return self:difference(other) end


function set:add(value)
if Not.Nil(value) then rawset(self, str(hash(value)), value) end end

function set:clear() for v in self() do self:remove(v) end end

function set:contains(value) return Not.Nil(rawget(self, str(hash(value)))) end

function set:difference(other)
local vs = set()
for v in self() do
if is.Nil(rawget(other, str(hash(v)))) then vs:add(v) end
end
return vs
end

function set:pop(value)
if value then
self:remove(value)
return value
else
local k, v = pairs(self)(self)
rawset(self, k, nil)
return v
end
end

function set:remove(value) rawset(self, str(hash(value)), nil) end

function set:update(other) for _, v in pairs(other) do self:add(v) end end

function set:values()
local result = {}
for v in self() do result[#result + 1] = v end
return result
end


local function add_locations(locations, other, relative)
if (relative and other[1].x == 0 and other[1].y == 0) or (locations[-1].x == other[1].x and locations[-1].y == other[1].y) then
other = other(2, nil)
end
local x, y
local new_locations = list()
for loc in iter(other) do
x, y = loc.x, loc.y
if relative then
x, y = x + locations[-1].x, y + locations[-1].y
end
new_locations:append({x=x, y=y})
end
return locations + new_locations
end


Path = class('Path')

function Path:__init(locations)
self.locations = list(locations or {})
self.point_count = len(locations)
self.duration = self.point_count * 0.016
self.absolute = true
end

function Path:__add(other)
assert(other:isinstance(Path), 'Can only add Path objects to other Path objects')
if len(self.locations) + len(other.locations) == 0 then return Path() end
if len(self.locations) == 0 then self.locations:append(other.locations[1]) end
return Path(add_locations(self.locations, other.locations, not other.absolute))
end

function Path:__index(key)
if is.num(key) then return self.locations[key] end
return class('').__index(self, key)
end

function Path:__newindex(key, value)
if is.num(key) then self.locations[key] = value end
class('').__newindex(self, key, value)
end

function Path:__pairs()
return pairs(self.locations)
end

function Path:__tostring()
return string.format('<%s(points=%s, duration=%.2fs)>', getmetatable(self).__name, len(self.locations), self.duration)
end


function Path:begin_swipe(fingerID, speed)
assert(speed and speed >= 1 and speed <= 10, 'speed '..speed..' is not in range 1-10')
touchDown(fingerID or 2, self.locations[1].x, self.locations[1].y)
usleep(16000)
self.cancelled = false
self.speed = speed or 5
self.idx = self.speed + 1
end

function Path:step(fingerID, on_move)
if is.Nil(on_move) then on_move = function() end end
if is.Nil(self.idx) then error('Cannot step a path before begin_swipe has been called') end
if self.idx < len(self.locations) and not self.cancelled then
touchMove(fingerID or 2, self.locations[self.idx].x, self.locations[self.idx].y)
self.idx = math.min(len(self.locations), self.idx + self.speed)
usleep(16000)
if on_move() == true then return true end
return false
else
touchUp(fingerID or 2, self.locations[self.idx].x, self.locations[self.idx].y)
self.idx = nil
self.cancelled = nil
self.speed = nil
return true
end
end

function Path:swipe(options)
with(screen.action_context(function() return true end), function(check)
self:begin_swipe(options.fingerID, options.speed)
local done = false
while not done do
done = self:step(options.fingerID, options.on_move)
end
end)
return screen
end

function Path.arc(radius, start_angle, end_angle, center)

-- Angle = 0 -> start_angle if no end_angle specified
if not end_angle then
start_angle, end_angle = 0, start_angle
end

local absolute = true
-- Relative path if no center specified
if not center then
-- TODO: make relative arc center adaptive to radius and angles
center = {x=0, y=0}
absolute = false
end

local function radians(a) return a / 360 * 2 * math.pi end
-- TODO: Better arc step resolution (for arcs with large radius)
local steps = abs(end_angle - start_angle)
local deltaTheta = (radians(end_angle) - radians(start_angle)) / steps
local theta = radians(start_angle)

local function angle_to_pos(angle)
return {x=center.x + radius * math.cos(angle), y=center.y + radius * math.sin(angle)}
end

local path = list{angle_to_pos(theta)}
for i=1, steps do
theta = theta + deltaTheta
path:append(angle_to_pos(theta))
end
if absolute then return Path(path) else return RelativePath(path) end
end

function Path.linear(start_pixel, end_pixel)
-- Relative path if only one pixel specified
local absolute = true
if not end_pixel then
start_pixel, end_pixel = {x=0, y=0}, start_pixel
absolute = false
end
local distanceX = end_pixel.x - start_pixel.x
local distanceY = end_pixel.y - start_pixel.y
local steps = math.min(50, math.max(math.abs(distanceX), math.abs(distanceY)))
local x, y = start_pixel.x, start_pixel.y
local deltaX = distanceX / steps
local deltaY = distanceY / steps
local path = list{{x=x, y=y}}
for i=1, steps do
x = x + deltaX
y = y + deltaY
path:append({x=x, y=y})
end
if absolute then return Path(path) else return RelativePath(path) end
end


RelativePath = class('RelativePath', 'Path')

function RelativePath:__init(locations)
Path.__init(self, locations)
self.absolute = false
end


function RelativePath:__add(other)
assert(other:isinstance(RelativePath), 'Can only add RelativePath objects to other RelativePath objects')
return RelativePath(add_locations(self.locations, other.locations, true))
end

local _stall = {count = 0, last_check=0, last_colors={}}
screen = {
before_action_funcs = set(),
after_action_funcs = set(),
before_check_funcs = set(),
after_check_funcs = set(),
before_tap_funcs = set(),
after_tap_funcs = set(),
on_stall_funcs = set()
}
if Not.Nil(getScreenResolution) then
screen.width, screen.height = getScreenResolution()
else
screen.width, screen.height = 200, 400
end

screen.check_interval = 150000
screen.stall_after_checks = 5               -- after 5 same screens
screen.stall_after_checks_interval = 3 * 60
screen.wait_before_action = 0
screen.wait_after_action = 0
screen.wait_before_tap = 0
screen.wait_after_tap = 0

screen.edge = {
top_left = Pixel(0, 0),                               -- x = 0, y = 0
top_right = Pixel(screen.width, 0),                   -- x = screen.width, y = 0
bottom_left = Pixel(0, screen.height),                -- x = 0, y = screen.height
bottom_right = Pixel(screen.width, screen.height)     -- x = screen.width, y = screen.height
}
screen.mid = {
left = Pixel(0, screen.height / 2),                   -- x = 0, y = screen.height / 2
right = Pixel(screen.width, screen.height / 2),       -- x = screen.width, y = screen.height / 2
top = Pixel(screen.width / 2, 0),                     -- x = screen.width / 2, y = 0
bottom = Pixel(screen.width / 2, screen.height),      -- x = screen.width / 2, y = screen.height
center = Pixel(screen.width / 2, screen.height / 2)   -- x = screen.width / 2, y = screen.height / 2
}
screen.stall_indicators = Pixels{
-- TODO: add more pixels for screen recovery check
screen.mid.center
}

getColor = getColor or function(...) return 0 end
getColors = getColors or function(...) return {0} end
tap = tap or function(...) end
touchDown = touchDown or function(...) end
touchMove = touchDown or function(...) end
touchUp = touchDown or function(...) end
usleep = usleep or function(...) end

local create_context = contextmanager(function(before_wait, after_wait, before_funcs, after_funcs)

sleep(before_wait)

for func in iter(before_funcs) do
func()
end

yield()

for func in iter(after_funcs) do
func()
end

sleep(after_wait)

end)


screen.action_context = contextmanager(function(condition)

local ctx = create_context(
screen.wait_before_action, screen.wait_after_action,
screen.before_action_funcs, screen.after_action_funcs
)

with(ctx, function()

local check

if is.func(condition) then
check = condition
else
check = function() return screen.contains(condition) end
end

yield(function()

for func in iter(screen.before_check_funcs) do
func()
end

-- Run stalling escape procedures if screen is stalled
if screen.is_stalled() then
for func in iter(screen.on_stall_funcs) do
func()
end
end

local result = check()

for func in iter(screen.after_check_funcs) do
func()
end

return result
end)

end)

end)

screen.tap_context = contextmanager(function()

local ctx = create_context(
screen.wait_before_tap, screen.wait_after_tap,
screen.before_tap_funcs, screen.after_tap_funcs
)

with(ctx, function() yield() end)

end)

function screen.before_action(func)
screen.before_action_funcs:add(func)
end

function screen.after_action(func)
screen.after_action_funcs:add(func)
end

function screen.before_check(func)
screen.before_check_funcs:add(func)
end

function screen.after_check(func)
screen.after_check_funcs:add(func)
end

function screen.before_tap(func)
screen.before_tap_funcs:add(func)
end

function screen.after_tap(func)
screen.after_tap_funcs:add(func)
end

function screen.on_stall(func)
local fs
if is.func(func) then fs = list{func} else fs = list(func) end
local cycler = itertools.cycle(iter(fs))
local t = {}
screen.on_stall_funcs:add(setmetatable(t, {
__call=function() return cycler()() end,
__hash=function() return tostring(t) end
}))
end

function screen.contains(pixel)
return pixel:visible()
end

function screen.is_stalled()
local current, previous
local now = os.time()
if now - _stall.last_check > screen.stall_after_checks_interval then
_stall.last_check = now
current = screen.stall_indicators.colors
local result = false
if requal(current, _stall.last_colors) then
_stall.count = _stall.count + 1
if _stall.count > screen.stall_after_checks then
result = true
end
else
_stall.count = 0
_stall.cyclers = list()
end
_stall.last_colors = current
return result
end

return false
end

function screen.tap(x, y, times, interval)
local pixel
if isType(x, 'number') then
pixel = Pixel(x, y)
else
pixel, times, interval = x, y, times
end

with(screen.tap_context(screen), function()
for i=1, times or 1 do
tap(pixel.x, pixel.y)
usleep(10000)
if interval then usleep(max(0, interval * 10 ^ 6 - 10000)) end
end
end)

return screen
end


function screen.tap_if(condition, to_tap)
with(screen.action_context(condition), function(check)

if check() then
screen.tap(to_tap or condition)
end

end)
return screen
end


function screen.tap_until(condition, to_tap)
with(screen.action_context(condition), function(check)

repeat
screen.tap(to_tap or condition)
usleep(screen.check_interval)
until check()

end)
return screen
end


function screen.tap_while(condition, to_tap)
with(screen.action_context(condition), function(check)

while check() do
screen.tap(to_tap or condition)
usleep(screen.check_interval)
end

end)
return screen
end


function screen.swipe(start_, end_, speed)
if is.str(start_) then
assert(screen.mid[start_] or screen.edge[start_],
'Incorrect identifier: use one of (left, right, top, bottom, center, top_left, top_right, bottom_left, bottom_right)')
start_ = screen.mid[start_] or screen.edge[start_]
end

if is.str(end_) then
assert(screen.mid[end_] or screen.edge[end_],
'Incorrect identifier: use one of (left, right, top, bottom, center, top_left, top_right, bottom_left, bottom_right)')
end_ = screen.mid[end_] or screen.edge[end_]
end

return Path.linear(start_, end_):swipe{speed=speed}
end


function screen.wait(condition)
with(screen.action_context(condition), function(check)

repeat
usleep(screen.check_interval)
until check()

end)
return screen
end

local pairs, ipairs, t_sort = pairs, ipairs, table.sort
local co_yield, co_wrap = coroutine.yield, coroutine.wrap
local co_resume = coroutine.resume
itertools = {}

function itertools.values (table)
return co_wrap(function ()
for _, v in pairs(table) do
co_yield(v)
end
end)
end

function itertools.each (table)
return co_wrap(function ()
for _, v in ipairs(table) do
co_yield(v)
end
end)
end

function itertools.collect (iterable)
local t, n = {}, 0
for element in iterable do
n = n + 1
t[n] = element
end
return t, n
end

function itertools.count (n, step)
if n == nil then n = 1 end
if step == nil then step = 1 end
return co_wrap(function ()
while true do
co_yield(n)
n = n + step
end
end)
end

function itertools.cycle (iterable)
local saved = {}
local nitems = 0
return co_wrap(function ()
for element in iterable do
co_yield(element)
nitems = nitems + 1
saved[nitems] = element
end
while nitems > 0 do
for i = 1, nitems do
co_yield(saved[i])
end
end
end)
end

function itertools.value (value, times)
if times then
return co_wrap(function ()
while times > 0 do
times = times - 1
co_yield(value)
end
end)
else
return co_wrap(function ()
while true do co_yield(value) end
end)
end
end

function itertools.islice (iterable, start, stop)
if start == nil then
start = 1
end
return co_wrap(function ()
if stop ~= nil and stop - start < 1 then
return
end

local current = 0
for element in iterable do
current = current + 1
if stop ~= nil and current > stop then
return
end
if current >= start then
co_yield(element)
end
end
end)
end

function itertools.takewhile (predicate, iterable)
return co_wrap(function ()
for element in iterable do
if predicate(element) then
co_yield(element)
else
break
end
end
end)
end

function itertools.map (func, iterable)
return co_wrap(function ()
for element in iterable do
co_yield(func(element))
end
end)
end

function itertools.filter (predicate, iterable)
return co_wrap(function ()
for element in iterable do
if predicate(element) then
co_yield(element)
end
end
end)
end

local function make_comp_func(key)
if key == nil then
return nil
end
return function (a, b)
return key(a) < key(b)
end
end

local _collect = itertools.collect

function itertools.sorted (iterable, key, reverse)
local t, n = _collect(iterable)
t_sort(t, make_comp_func(key))
if reverse then
return co_wrap(function ()
for i = n, 1, -1 do co_yield(t[i]) end
end)
else
return co_wrap(function ()
for i = 1, n do co_yield(t[i]) end
end)
end
end

iter = itertools.values



TransitionTree = class('TransitionTree')

function TransitionTree:__init(name, parent, forward, backward)
self.name = name or 'root'
self.parent = parent
if is.Nil(backward) then self.backward = forward
else
self.forward = forward
self.backward = backward
end
self.nodes = {}
end

function TransitionTree:__index(value)
return rawget(TransitionTree, value) or rawget(self, value) or self.nodes[value]
end

function TransitionTree:add(name, forward, backward)
self.nodes[name] = TransitionTree(name, self, forward, backward)
end

function TransitionTree:path_to_root()
local path = list{self}
local parent = self.parent
while Not.Nil(parent) do
path:append(parent)
parent = parent.parent
end
return path
end

function TransitionTree:path_to(name)
local q = list()
for i, v in pairs(self.nodes) do q:append({i, v}) end
local item
while len(q) > 0 do
item = q:pop(1)
for i, v in pairs(item[2].nodes) do q:append({i, v}) end
if item[1] == name then return reversed(item[2]:path_to_root()) end
end
end

function TransitionTree:lca(name1, name2)
local lca = 'root'
local v1, v2
local path1, path2 = self:path_to(name1), self:path_to(name2)
for i=2, math.min(len(path1), len(path2)) do
v1, v2 = path1[i], path2[i]
if v1.name == v2.name then lca = v1.name; break end
if v1.parent ~= v2.parent then break else lca = v1.parent.name end
end
return lca
end

function TransitionTree:navigate(start, _end)
local counting = false
local lca = self:lca(start, _end)
local path1, path2 = reversed(self:path_to(start)), self:path_to(_end)
for i, v in pairs(path1) do
if v.name == lca then break end
v.backward()
end

for i, v in pairs(path2) do
if counting then v.forward() end
if v.name == lca then counting = true end
end
end



Navigator = class('Navigator')
