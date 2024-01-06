local model = "Label"
local modelicon = "fas fa%-font"
local new = "Progressbar"
local newicon = "fas fa-minus"



for entry in each(sys.Directory():list(model.."*.html")) do
    local newfile = sys.File(entry.name:gsub(model, new)):open("write")
    newfile:write(entry:open():read():gsub(model, new):gsub(modelicon, newicon))
    newfile:close()
    print(newfile.name)
end
