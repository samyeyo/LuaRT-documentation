local ctypes = { "uchar","char","wchar_t","short","ushort",	"int",	"uint",	"bool",	"long", "longlong",	"ulong","ulonglong","float","double","size_t","int16_t","int32_t","int64_t","uint16_t","uint32_t","uint64_t","string","wstring"}
local cnames = { "unsigned char","char","wchar_t","short","unsigned short",	"int",	"unsigned int",	"bool",	"long", "long long", "unsigned long","unsigned longlong","float","double","size_t","int16_t","int32_t","int64_t","uint16_t","uint32_t","uint64_t","char *","wchar_t *"}
local init = { "128","'A'","'Ô'","-320","320",	"12800",	"12800",	"true",	"-1234567890", "9876543210987654321", "1234567890","18446744073709551615","3.14","3.141592653589793","1024","-32767","2147483647","9223372036854775807","65535","4294967295","18446744073709551615","'Hello LuaRT'","'Hello LuaRT'"}
local templates = { "ctype.html"}

local i = 0

for ctype in each(ctypes) do
    i = i + 1;
    for template in each(templates) do 
        local fname = ctype..'.html'
        print(fname)
        local file = sys.File(fname):open("write")
        file:write(sys.File(template):open():read():gsub("<NAME>", ctype):gsub("<CNAME>", cnames[i]):gsub("<INIT>", init[i]))
        file:close()
    end
end