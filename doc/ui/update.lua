local widgets = { "Button", "Calendar", "Checkbox", "Combobox", "Edit", "Entry", "Groupbox", "Label", "List", "Tab", "Panel", "Picture", "Progressbar", "Radiobutton", "Tree", "Window" }

local templates = { "onDrop.html", "allowdrop.html" }

for widget in each(widgets) do
    for template in each(templates) do 
        local fname = widget.."-"..template
        print(fname)
        local file = sys.File(fname):open("write")
        file:write(sys.File(template):open():read():gsub("<NAME>", widget))
        file:close()
    end
end