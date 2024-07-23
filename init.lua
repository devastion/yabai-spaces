local obj = {}

-- Metadata
obj.name = "YabaiSpaces"
obj.version = "0.1"
obj.author = "Dimitar Banev <banev_dimitar@mail.com>"
obj.homepage = "https://github.com/devastion/yabaispaces"
obj.license = "MIT - https://opensource.org/licenses/MIT"

-- Internals
obj.menu = nil
obj.watcher = nil
obj.log = hs.logger.new("YabaiSpaces", "debug")

function obj:_getCurrentSpace()
  local output = hs.execute("yabai -m query --spaces --space", true)
  local space = hs.json.decode(output)

  if space.label == "" then
    return tostring(space.index)
  else
    return space.label
  end
end

function obj:_goToSpace(spaceId)
  hs.execute("yabai -m space --focus " .. spaceId, true)
end

function obj:_getMenuItems()
  local menuItems = {}
  local current = obj:_getCurrentSpace()

  local displaysOutput = hs.execute("yabai -m query --displays", true)
  local displays = hs.json.decode(displaysOutput)
  local displaysLength = #displays

  local function menuItemsHelper(displayIdx)
    local spacesOutput = hs.execute("yabai -m query --spaces --display " .. displayIdx, true)
    local spaces = hs.json.decode(spacesOutput)

    for _key, val in pairs(spaces) do
      table.insert(menuItems, {
        title = tostring(displayIdx) .. ": " .. string.upper(val.label),
        fn = function()
          obj:_goToSpace(val.label)
        end,
        checked = (current == val.label) or (current == val.index),
        disabled = (current == val.label) or (current == val.index),
      })
    end
  end

  for _key, val in pairs(displays) do
    menuItemsHelper(val.index)
  end

  table.insert(menuItems, {
    title = "-",
  })

  table.insert(menuItems, {
    title = "Edit space label",
    fn = function()
      local current = obj:_getCurrentSpace()
      local button, newSpaceName = hs.dialog.textPrompt("Rename space", "", current, "Save", "Cancel")
      if button == "Save" and newSpaceName ~= "" then
        hs.execute("yabai -m space " .. current .. " --label " .. newSpaceName, true)
        obj:_updateMenuTitle()
      end
    end,
  })
  return menuItems
end

function obj:_updateMenu()
  local menuBarItems = obj:_getMenuItems()
  local menuBarTitle = string.upper(obj:_getCurrentSpace())

  obj.menu:setMenu(menuBarItems)
  obj.menu:setTitle(menuBarTitle)
end

function obj:init()
  obj.menu = hs.menubar.new()
  obj._updateMenu()

  obj.watcher = hs.spaces.watcher.new(obj._updateMenu)
  obj.watcher:start()
end

return obj
