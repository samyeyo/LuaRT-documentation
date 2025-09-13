local json = require "json"
local console = require("console")

local colors = { ['function'] = "is-warning", method = "is-primary", event = "is-link" }

local function template(from, to, vars)
    local template = sys.File("templates\\"..from):open():read()
    for var, content in pairs(vars) do
        local _ = content:gsub("%%", "§")
        template = template:gsub("{{"..var.."}}", _)
    end
    local file = sys.File("build\\doc\\"..to):open("write")
    file:write(template:gsub("§", "%%"))
    file:close()
end

local Module = Object{}
local object = Object(Module)

function Module:constructor(item)
    self.content = item
    self.filename = self.content.__filename
    self.name = item.__name or error("module not found in JSON file")
    self.properties = {}
    self.objects = {}
    self.events = {}
    self.functions = {}
    self.operations = {}
end

function Module:generate_operation(item)
    local filename = item.__filename or error("Expecting __filename for '"..self.name.."."..item.__name..'"')
    local tinydesc = item.__tinydesc or error("Expecting __tinydesc for '"..item.__name..'"')
    self.operations[#self.operations+1] = string.format([[
                        <tr draggable="false">
                          <td><a style="font-weight:600" href="%s">%s</a></td>
                          <td><span>%s</span></td>
                        </tr>           
    ]], filename:gsub('(#.+)$', ''), item.__name, tinydesc)
    if item.__example ~= nil then
        item.__example = [[
                        <p class="has-text-weight-medium is-size-6 mt-6 mb-0" style="color: #004080">Example</p>
                            <div class="language-lua mr-6 ml-6"><code>
]]..item.__example..[[

            </code></div>]]
    end
    local vars = {
        parent = type(self)== "Module" and 'index' or self.name,
        name = item.__name,
        filename = filename:gsub('(#.+)$', ''),
        tinydesc = tinydesc or "",
        description =  item.__description or error("expecting __description for '"..self.name.."."..item.__name.."'"),
        example = item.__example and item.__example..'\n' or "",
        module = self.name,
        title = item.__title,
    }
    template("operation.tpl", (self.module and self.module.name or self.name).."\\"..item.__filename:gsub('(#.+)$', ''), vars)
    self.isoperations = true
end

function Module:generate_results(item)
    local results = item.__results:gsub('|', " "):gsub('<br>', ' ')
    local values
    if results:find("<a") ~= nil then
        values = ""
        for item, name in results:gmatch("(<a.-%s?(%w+)</a>)") do
            if item:find("<sup>") ~= nil then
                values = values..item:gsub("(<a.-<i.-</i></sup>)%s?(%w+)</a>", '<span data-tooltip="%2" class="mr-1 has-tooltip-bottom has-tooltip-info has-tooltip-arrow has-text-info>%1</a></span>')
            else
                values = values..item:gsub("(<a.-<i.-</i>)%s(%w+)</a>", '<span data-tooltip="%2" class="mr-1 has-tooltip-bottom has-tooltip-info has-tooltip-arrow has-text-info">%1</a></span>')
            end
        end
        values = values:gsub('(.*)mr%-1(.-)$', "%1%2")
    end
    return values or results
end

function Module:generate_property(item)
    local filename = item.__filename or error("Expecting __filename for '"..self.name.."."..item.__name..'"')
    local tinydesc = item.__tinydesc or error("Expecting __tinydesc for '"..item.__name..'"')
    local access = item.__access == "read/write" and '<td><span class="tag is-rounded has-text-weight-medium has-background-warning has-text-warning-dark" mt-0 style="vertical-align: middle; font-size: 0.65em">readwrite</span></td>' or '<td><span class="tag is-rounded has-text-weight-medium has-background-danger-light has-text-danger mt-0" style="vertical-align: middle; font-size: 0.65em"">readonly</span></td>'
    self.properties[#self.properties+1] = string.format([[
                        <tr draggable="false">
                        <td><a style="font-weight:600" href="%s">%s.%s</a></td>
                          <td><span>%s</span></td>
                          %s
                          <td><span>%s</span></td>
                        </tr>           
    ]], filename, self.name, item.__name, tinydesc, access, self:generate_results(item))
    local vars = {
        parent = self.name,
        name = item.__name,
        filename = filename,
        tinydesc = tinydesc,
        description = item.__description or error("Expecting __description for '"..item.__name..'"'),
        index = self.filename,
        access = access,
        example = item.__example,
        results = item.__results
    } 
    template("property.tpl", (type(self) == "Module" and self.name or self.module.name).."\\"..filename, vars)
    self.isproperties = true
end

function Module:generate_object(item)
    local filename = item.__filename or error("Expecting __filename for '"..self.name.."."..item.__name..'"')
    local tinydesc = item.__tinydesc or error("Expecting __tinydesc for '"..item.__name..'"')
    local icon = item.__icon or error("Expecting __icon for '"..self.name.."."..item.__name..'"')
    self.objects[#self.objects+1] = string.format([[
                        <tr draggable="false">
                            <td><a style="font-weight:600" href="%s">%s %s</a></td>
                            <td><span>%s</span></td>
                        </tr>   
    ]], filename, icon, item.__name, tinydesc)
    object(item, self):generate()
    self.isobjects = true
end

function Module:generate_function(item)
    local fullname
    if self.name == "base" then
        fullname = item.__name
    else
        fullname = string.format("%s%s%s", self.name, (type(self) == "Module") and "." or ":", item.__name)
    end
    self.functions[#self.functions+1] = string.format([[
                        <tr draggable="false">
                          <td><a style="font-weight:600" href="%s">%s</a></td>
                          <td><span>%s</span></td>
                          <td><span>%s</span></td>
                        </tr>           
    ]], item.__filename, fullname.."()", item.__tinydesc, self:generate_results(item))
    if not item.__filename:match("^https?://") then
        local parameters = #item.__params > 0 and '<p class="has-text-weight-medium is-size-6 mb-1 mt-6" style="color: #004080">Parameters</p>\n\t' or ""
        local paramlist = ""
        for param in each(item.__params) do
            local formatted = string.format('<span style="color: #%s">%s</span>', param.__color, param.__optional and "["..param.__name.."]" or param.__name)
            paramlist = paramlist..formatted..", "
            parameters = parameters..string.format([[
            <p class="has-text-weight-medium is-size-6 mt-2 mb-0">%s</p>
                %s
        ]], formatted, param.__description)
        end
        if not item.__returns then
            if item.__name == "constructor" then
                item.__returns = "The constructor returns a new "..item.__results.." instance."
            else
                item.__returns = "This "..item.__kind.." returns no value"
            end
        end

        local vars = {
            parent = self.name,
            fullname = fullname,
            name = item.__name,
            filename = item.__filename,
            tinydesc = item.__tinydesc,
            description = item.__description,
            index = self.filename,
            example = item.__example,
            returns = item.__returns,
            parameters = parameters,
            list = "methods",
            paramlist = paramlist:sub(1, -3),
            color = item.__name == "constructor" and "is-danger" or colors[item.__kind],
            funckind = item.__name == "constructor" and "constructor" or item.__kind,
            results = item.__results
        }
        template("function.tpl", (type(self) == "Module" and self.name or self.module.name).."\\"..item.__filename, vars)
    end
    self.isfunctions = true
end

function Module:generate_method(item)
    self:generate_function(item)
end

function Module:generate_event(item)
    local fullname = string.format("%s%s%s", self.name, (type(self) == "Module") and "." or ":", item.__name)
    self.events[#self.events+1] = string.format([[
                        <tr draggable="false">
                        <td><a style="font-weight:600" href="%s">%s()</a></td>
                        <td><span>%s</span></td>
                        </tr>           
                        ]], item.__filename, fullname, item.__tinydesc)
    local parameters = #item.__params > 0 and '<p class="has-text-weight-medium is-size-6 mb-1 mt-6" style="color: #004080">Parameters</p>\n\t' or ""
    local paramlist = ""
    for param in each(item.__params) do
        local formatted = string.format('<span style="color: #%s">%s</span>', param.__color, param.__optional and "["..param.__name.."]" or param.__name)
        paramlist = paramlist..formatted..", "
        parameters = parameters..string.format([[
            <p class="has-text-weight-normal is-size-6 mt-2 mb-0">%s</p>
            %s
    ]], formatted, param.__description)
    end
    local vars = {
        parent = self.name,
        name = item.__name,
        fullname = fullname,
        filename = item.__filename,
        tinydesc = item.__tinydesc,
        description = item.__description,
        index = self.filename,
        example = item.__example,
        returns = item.__returns or "This event returns no value",
        list = "events",
        parameters = parameters,
        paramlist = paramlist:sub(1, -3),
        color = colors.event,
        funckind = "event"
    }
    template("function.tpl", (type(self) == "Module" and self.name or self.module.name).."\\"..item.__filename, vars)
    self.isevents = true
end

function Module:list_objects(id)
    table.sort(self.objects)
    self.objects = table.concat(self.objects)
    return #self.objects > 0 and [[
        <div data-content="]]..id..[[" ]]..(self.isactive ~= id and '' or 'class="is-active"') ..[[>
          <table class="table">
            <thead><tr>
                  <th draggable="false"><span class="is-relative"> Object </span</th>
                  <th draggable="false"><span class="is-relative"> Description </span></th>
            </tr></thead>
            <tbody>
            ]]..self.objects..[[
                </tbody>
          </table>
        </div>            
        ]] or '<div data-content="'..id..'"><p class="has-text-centered mt-6 mb-6"><i>'..self.name..' '..type(self):lower()..' does not have any objects</i></p></div>\n'
end
    
function Module:list_properties(id)        
    table.sort(self.properties)
    self.properties = table.concat(self.properties)
    return #self.properties > 0 and [[
        <div data-content="]]..id..[[" ]]..(self.isactive ~= id and '' or 'class="is-active"')..[[>
            <table class="table">
              <thead><tr>
                <th draggable="false"><span class="is-relative"> Property</span></th>
                <th draggable="false"><span class="is-relative"> Description </span></th>
                <th draggable="false"><span class="is-relative"> Access</span></th>
                <th draggable="false"><span class="is-relative"> Type</span></th>
              </tr></thead>
              <tbody>
                      ]]..self.properties..[[
              </tbody>
              </table>
            </div>            
    ]] or '<div data-content="'..id..'"><p class="has-text-centered mt-6 mb-6"><i>'..self.name..' '..type(self):lower()..' does not have any properties</i></p></div>\n'
end

function Module:list_functions(id)
    table.sort(self.functions)
    self.functions = table.concat(self.functions)
    return #self.functions > 0 and [[
        <div data-content="]]..id..[[" ]]..(self.isactive ~= id and '' or 'class="is-active"') ..[[>
          <table class="table">
            <thead><tr>
              <th draggable="false"><span class="is-relative"> ]]..(type(self) == "Module" and "Functions" or "Methods")..[[ </span</th>
              <th draggable="false"><span class="is-relative"> Description </span></th>
              <th draggable="false"><span class="is-relative"> Return value </span></th>
            </tr></thead>
            <tbody>
                  ]]..self.functions..[[
          </tbody>
          </table>
        </div>            
    ]] or '<div data-content="'..id..'"><p class="has-text-centered mt-6 mb-6"><i>'..self.name..' '..type(self):lower()..' does not have any functions</i></p></div>\n'
end

function Module:list_events(id)
    table.sort(self.events)
    self.events = table.concat(self.events)
    return #self.events > 0 and [[
        <div data-content="]]..id..[[">
          <table class="table">
            <thead><tr>
              <th draggable="false"><span class="is-relative"> Event</span></th>
              <th draggable="false"><span class="is-relative"> Description </span></th>
              </tr></thead>
              <tbody>
                  ]]..self.events..[[
          </tbody>
          </table>
        </div>            
    ]] or '<div data-content="'..id..'"><p class="has-text-centered mt-6 mb-6"><i>'..self.name..' '..type(self):lower()..' does not have any events</i></p></div>\n'
end

function Module:list_operations(id)
    table.sort(self.operations)
    self.operations = table.concat(self.operations)
    return #self.operations > 0 and [[
        <div data-content="]]..id..[[">
            <table class="table">
            <thead><tr>
                <th draggable="false"><span class="is-relative"> Operation</span></th>
                <th draggable="false"><span class="is-relative"> Description </span></th>
                </tr></thead>
                <tbody>
                    ]]..self.operations..[[
            </tbody>
            </table>
        </div>            
    ]] or '<div data-content="'..id..'"><p class="has-text-centered mt-6 mb-6"><i>'..self.name..' '..type(self):lower()..' does not support operations</i></p></div>\n'
end    


function Module:generate_items()
    for _, item in pairs(self.content) do
        if item.__kind ~= nil then
            if item.__example then
                item.__example = item.__example:gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("§", "%%")
            end
            local method = self["generate_"..item.__kind] or error("Unknown item kind '"..item.__kind.."'")
            method(self, item)
        end
    end
end

function Module:generate()
    console.write("Generating ")
    console.writecolor("blue", self.name)
    console.writeln(" documentation...")
    sys.Directory("build\\doc\\"..self.name):make()
    self:generate_items()
    local core = self.content.__kind.iscore and '<span data-tooltip="Module belongs to the LuaRT Core framework" class="tag is-rounded is-small has-background-success-light has-text-success-dark has-tooltip-bottom has-tooltip-success has-tooltip-arrow"><span><i class="fas fa-check has-text-success"></i> Core framework</span></span>'
                 or '<span data-tooltip="Module is available as a binary module" class="tag is-rounded is-small has-background-danger-light has-text-danger-dark has-tooltip-bottom has-tooltip-danger has-tooltip-arrow"><span><i class="fas fa-xmark has-text-danger"></i> Core framework</span></span>'  
    local desktop = self.content.__kind.isdesktop and '<span data-tooltip="Module is depends on wluart.exe interpreter" class="tag is-rounded is-small has-background-info-light has-tooltip-bottom has-tooltip-info has-tooltip-arrow has-text-info"><span><i class="fab fa-windows"></i> Desktop</span></span>'
                    or ''
    local isconsole = self.content.__kind.isconsole and '<span data-tooltip="Module is available with luart.exe interpreter" class="tag is-rounded is-small has-background-info-light has-tooltip-bottom has-tooltip-info has-tooltip-arrow has-text-info"><span><i class="fas fa-window-maximize"></i> Console</span></span>'
                    or ''
    if self.content.__description == "" then
        print("Warning : "..type(self):capitalize().." '"..self.name.."' don't have a description")
    end                
    if self.isproperties then self.isactive = 3 end
    if self.isfunctions then self.isactive = 2 end
    if self.isobjects then self.isactive = 1 end

    local vars = {
        name = self.name,
        filename = self.content.__filename,
        description = self.content.__description or "",
        icon = self.content.__icon,
        color = self.content.__color,
        availability = core..'\n'..isconsole..'\n'..desktop..'\n',
        properties = self.isproperties and self:list_properties(3) or '',
        objects = self.isobjects and self:list_objects(1) or '',
        functions = self.isfunctions and self:list_functions(2) or '',
        isobjects = self.isobjects and '<li id="objects" data-tab="1" {{tab_obj}}><a><span><span class="icon mx-0"><i class="fa fa-shapes"></i></span>Objects</span></a></li>' or '',
        isfunctions = self.isfunctions and '<li id="methods" data-tab="2" {{tab_func}}><a><span><span class="icon mx-0"><i class="fa fa-bolt"></i></span>Functions</span></a></li>' or '',
        isproperties = self.isproperties and '<li id="properties" data-tab="3" {{tab_prop}}><a><span class="icon mx-0"><i class="fa fa-tag"></i></span>Properties</span></a></li>' or '',
        isoperations = self.isoperations and '<li id="operations" data-tab="5"><a><span class="icon mx-0"><i class="fa fa-screwdriver-wrench"></i></span>Operations</span></a></li>' or '',
        isevents = self.isevents and '<li id="events" data-tab="4"><a><span class="icon mx-0"><i class="fa fa-paper-plane"></i></span>Events</span></a></li>' or '',
        events = self.isevents and self:list_events(4) or '',
        operations = self.isoperations and self:list_operations(5) or '',
    }
    if #self.objects > 0 then
        vars.isobjects = vars.isobjects:gsub("{{tab_obj}}", 'class="is-active"')
        vars.isfunctions = vars.isfunctions:gsub("{{tab_func}}", '')
        vars.isproperties =vars.isproperties:gsub("{{tab_prop}}", '')
    elseif #self.functions > 0 then
        vars.isobjects = vars.isobjects:gsub("{{tab_obj}}", '')
        vars.isfunctions =vars.isfunctions:gsub("{{tab_func}}", 'class="is-active"')
        vars.isproperties = vars.isproperties:gsub("{{tab_prop}}", '')
    else 
        vars.isobjects = vars.isobjects:gsub("{{tab_obj}}", '')
        vars.isfunctions = vars.isfunctions:gsub("{{tab_func}}", '')
        vars.isproperties = vars.isproperties:gsub("{{tab_prop}}", 'class="is-active"')
    end
    template("module.tpl", self.name.."\\index.html", vars)
end

function object:constructor(item, module)
    self.module = module
    self.content = item
    self.filename = item.__filename
    self.name = item.__name
    self.properties = {}
    self.events = {}
    self.functions = {}
    self.operations = {}
end

function object:generate()
    self:generate_items()
    if self.content.__description == nil then
        print("\nWarning : "..type(self):capitalize().." '"..self.name.."' don't have a description")
    end                
    
    if self.isproperties then self.isactive = 3 end
    if self.isfunctions then self.isactive = 2 end
    -- if self.isobjects then self.isactive = 1 end

    local vars = {
        name = self.name,
        filename = self.content.__filename,
        description = self.content.__description or "",
        icon = self.content.__icon,
        color = self.content.__color,
        properties = self.isproperties and self:list_properties(3) or '',
        objects = self.isobjects and self:list_objects(1) or '',
        functions = self.isfunctions and self:list_functions(2) or '',
        events = self.isevents and self:list_events(4) or '',
        operations = self.isoperations and self:list_operations(5) or '',
        isfunctions = self.isfunctions and '<li id="methods" data-tab="2" {{tab_func}}><a><span><span class="icon mx-0"><i class="fa fa-bolt"></i></span>Methods</span></a></li>' or '',
        isproperties = self.isproperties and '<li id="properties" data-tab="3" {{tab_prop}}><a><span class="icon mx-0"><i class="fa fa-tag"></i></span>Properties</span></a></li>' or '',
        isoperations = self.isoperations and '<li id="operations" data-tab="5"><a><span class="icon mx-0"><i class="fa fa-screwdriver-wrench"></i></span>Operations</span></a></li>' or '',
        isevents = self.isevents and '<li id="events" data-tab="4"><a><span class="icon mx-0"><i class="fa fa-paper-plane"></i></span>Events</span></a></li>' or '',
        module = self.module.name
    }

    if #self.functions > 0 then
        vars.isfunctions =vars.isfunctions:gsub("{{tab_func}}", 'class="is-active"')
        vars.isproperties = vars.isproperties:gsub("{{tab_prop}}", '')
    else 
        vars.isfunctions = vars.isfunctions:gsub("{{tab_func}}", '')
        vars.isproperties = vars.isproperties:gsub("{{tab_prop}}", 'class="is-active"')
    end
    template("object.tpl", self.module.name.."\\"..self.filename, vars)
end

local function generate_file(f)
    local module = json.load("..\\json\\"..f..".json") or error("file '"..f.."' not found")
    Module(module):generate()
end

function generate_modules()
    local items = {}
    for entry in each(sys.Directory("build\\doc\\")) do
        if type(entry) == "Directory" then
            local item = json.load("..\\json\\"..entry.name..".json")
            items[#items+1] = string.format([[
                <a class="bd-link" href="%s/index.html">
                  <span class="icon bd-link-icon" style="font-size: 2em">%s</span>
                  <div class="bd-link-body">
                    <h3 class="bd-link-title has-text-weight-normal" style="margin-bottom: 0; color: #004080;">%s</h3>
                    <div class="bd-link-subtitle">%s</div>  
                  </div>
                </a>]], item.__name, item.__icon, item.__name, item.__tinydesc)
        end
    end
    local vars = {
        items = table.concat(items)
    }
    template("modules.tpl", "modules.html", vars)
end

local t1 = sys.clock()

if #arg > 0 then
    for _, f in ipairs(arg) do
        generate_file(f)
    end
else
    for file in each(sys.Directory("..\\json\\"):list("*.json")) do
        generate_file(file.name:gsub(file.extension, ""))
    end
end
generate_modules()
    
local t2 = sys.clock()

console.write("\nLuaRT documentation generated in ")
console.writecolor("purple", math.floor(t2-t1)/1000)
console.writeln(" seconds")

