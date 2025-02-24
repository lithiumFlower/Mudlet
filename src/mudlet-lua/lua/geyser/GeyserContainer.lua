--------------------------------------
--                                  --
-- The Geyser Layout Manager by guy --
--                                  --
--------------------------------------

--- Represents a generic container with positional information.
-- Has no notion of contents and is used to contain other windows
-- and impose some sense of order.
-- @class table
-- @name Geyser.Container
-- @field parent The parent class of this window
-- @field type The type of this window, usually lowercase of the classname and
--             can be used in checks for certain types. For a Container
--             instance, type is “container.”
-- @field name The name of this window. This is the same name that Mudlet will
--             use internally for primitive types like labels and
--             miniconsoles.  If not specified in the constraints table during
--             creation, an anonymous name unique to this session will be
--             made up.
-- @field x The x-coordinate relative to this window's container, not absolute
--          from the Mudlet main window. This is not a number, but a
--          constraint specification. To find out the numeric x-coordinate in
--          terms of pixels from the Mudlet main window's origin, use the
--          get_x() method. Default is "10px".
-- @field y The y-coordinate relative to this window's container, not absolute
--          from the Mudlet main window. This is not a number, but a
--          constraint specification. To find out the numeric y-coordinate in
--          terms of pixels from the Mudlet main window's origin, use the
--          get_y() method. Default is "10px".
-- @field width The width of this window, possibly relative to the window's
--              container. This is not a number, but a constraint
--              specification. To find out the numeric width in terms of
--              pixels, use the get_width() method. Default is "300px".
-- @field height The height of this window, possibly relative to the window's
--               container. This is not a number, but a constraint
--               specification. To find out the numeric width in terms of
--               pixels, use the get_width() method. Default is "200px".
-- @field windowList This is a list of all windows held by this container. It
--                   used to handle proper resizing of held windows as well as
--                   during show()s and hide()s to recursive show and hide all
--                   children windows.
-- @field windows This is an ordered list of the names of the window held by this container.
-- @field fontSize The default size font used when calculating dimensions
--                 based on the character constraint. Default is 8.
-- @field h_policy This sets if this widget should be stretched/shrunk horizontally or not
-- @field v_policy This sets if this widget should be stretched/shrunk vertically or not
-- @field v_stretch_factor This sets by how much more then window will be stretched horizontally in comparison to
--                 other windows
-- @field v_stretch_factor This sets by how much more then window will be stretched vertically in comparison to
--                 other windows

Geyser.Container = {
  name = "ContainerClass",
  x = "10px",
  y = "10px",
  height = "200px",
  width = "300px",
  windowList = {},
  windows = {},
  fontSize = 8,
  h_policy = Geyser.Dynamic,
  v_policy = Geyser.Dynamic,
  h_stretch_factor = 1.0,
  v_stretch_factor = 1.0,
}

function Geyser.Container:calculate_dynamic_window_size()
  local total_count = #self.windows
  local fixed_horizontal_count = 0
  local fixed_vertical_count = 0
  local fixed_width_sum = 0
  local fixed_height_sum = 0
  local ret_size = {}
  ret_size.width = self.get_width()
  ret_size.height = self.get_height()
  local dynamic_horizontal_count = 0.0
  local dynamic_vertical_count = 0.0

  if total_count <= 1 then
    --If there is only one window it can have all the width/height, if there are none then it doesn't matter
    return ret_size
  end
  for _, window in pairs(self.windowList) do
    if window.h_policy == Geyser.Fixed then
      fixed_horizontal_count = fixed_horizontal_count + 1
      fixed_width_sum = fixed_width_sum + window.get_width()
    else
      dynamic_horizontal_count = dynamic_horizontal_count + window.h_stretch_factor - 1.0
    end
    if window.v_policy == Geyser.Fixed then
      fixed_vertical_count = fixed_vertical_count + 1
      fixed_height_sum = fixed_height_sum + window.get_height()
    else
      dynamic_vertical_count = dynamic_vertical_count + window.v_stretch_factor - 1.0
    end
  end
  dynamic_horizontal_count = dynamic_horizontal_count + total_count - fixed_horizontal_count
  dynamic_vertical_count = dynamic_vertical_count + total_count - fixed_vertical_count
  if dynamic_horizontal_count == 0 then
    ret_size.width = 0
  else
    ret_size.width = (self.get_width() - fixed_width_sum) / dynamic_horizontal_count
  end
  if dynamic_vertical_count == 0 then
    ret_size.height = 0
  else
    ret_size.height = (self.get_height() - fixed_height_sum) / dynamic_vertical_count
  end
  return ret_size
end

--- Responsible for placing/moving/resizing this window to the correct place/size.
-- Called on window resize events.
function Geyser.Container:reposition ()
  local x, y, w, h = self:get_x(), self:get_y(), self:get_width(), self:get_height()
  if self.type ~= "userwindow" then
    moveWindow(self.name, self:get_x(), self:get_y())
    resizeWindow(self.name, self:get_width(), self:get_height())
  end
  -- deal with all children of this container
  for k, v in pairs(self.windowList) do
    if k ~= self and not v.nestLabels then
      v:reposition()
    end
  end

  -- Calls optional redraw method if it is available to cause a gui element to
  -- redraw itself after moving.
  if self.redraw then
    self:redraw()
  end
end

--- Hides this window and all its contained windows.
function Geyser.Container:hide (auto)
  if not (self.hidden or self.auto_hidden) then
    self:hide_impl()
  end
  auto = auto or false
  if auto then
    self.auto_hidden = true
  else
    self.hidden = true
  end
  for _, v in pairs(self.windowList) do
    v:hide(true)
  end
end

function Geyser.Container:hide_impl()
  hideWindow(self.name)
end

--- Shows this window and all windows it contains.
function Geyser.Container:show (auto)
  auto = auto or false
  -- If my container is hidden I stay hidden and after it get visible again I'm visible too
  if self.container.hidden or self.container.auto_hidden then
    if auto == false then
      self.hidden = false
    end
    return false
  end
  if auto then
    self.auto_hidden = false
  else
    self.hidden = false
  end

  if not self.hidden and not self.auto_hidden then
    self:show_impl()
  end
  for _, v in pairs(self.windowList) do
    v:show(true)
  end
end

function Geyser.Container:show_impl()
  showWindow(self.name)
end

--- Raises the window to the top of the z-order stack, displaying in front of all other windows
--@param changeWindowIndex used internally
--@see Geyser.Container:raiseAll
function Geyser.Container:raise (changeWindowIndex)
  raiseWindow(self.name)
  if changeWindowIndex ~= false then
    local index = table.index_of(self.container.windows, self.name)
    if index == #self.container.windows then
      return
    end
    local tempValue = self.container.windows[index]
    table.remove(self.container.windows, index)
    self.container.windows[#self.container.windows+1] = tempValue
  end
end

--- Lowers the window to the bottom of the z-order stack, displaying behind all other windows
--@param changeWindowIndex used internally
--@see Geyser.Container:lowerAll
function Geyser.Container:lower (changeWindowIndex)
  lowerWindow(self.name)
  if changeWindowIndex ~= false then
    local index = table.index_of(self.container.windows, self.name)
    if index == 1 then
      return
    end
    local tempValue = self.container.windows[index]
    table.remove(self.container.windows, index)
    table.insert(self.container.windows, 1, tempValue)
  end
end

--- Raises the window and all its containing elements to the top of the z-order stack, displaying in front of all other windows.
--@param container used internally
--@param me used internally
--@see Geyser.Container:raise
function Geyser.Container:raiseAll(container, me)
  container = container or self
  -- raise myself
  if me ~= false then
    container:raise()
  end
  local v
  for i=1, #container.windows do
    v = container.windows[i]
    container.windowList[v]:raise(false)
    container.windowList[v]:raiseAll(container.windowList[v], false)
  end
end

local function createWindowTable(container)
  local v
  Geyser.Container.windowTable = Geyser.Container.windowTable or {}
  for i=1, #container.windows do
    v = container.windows[i]
    Geyser.Container.windowTable[#Geyser.Container.windowTable+1] = container.windowList[v]
    createWindowTable(container.windowList[v])
  end
end

--- Lowers the window and all its containing elements to the bottom of the z-order stack, displaying behind all other windows
--@see Geyser.Container:lower
function Geyser.Container:lowerAll()
  createWindowTable(self)
  -- iterate in reverse order through all elements to keep the same z-axis inside the container
  for i=#Geyser.Container.windowTable,1,-1 do
    Geyser.Container.windowTable[i]:lower(false)
  end
  Geyser.Container.windowTable = nil
  self:lower()
end

--- Moves this window according to the new x and y constraints set.
-- @param x New x constraint to use. If nil, uses current value.
-- @param y New y constraint to use. If nil, uses current value.
function Geyser.Container:move (x, y)
  self.x = x or self.x
  self.y = y or self.y
  self:set_constraints(self)
end

--- Resizes this window according to the new width and height constraints set.
-- @param width New width constraint to use.  If nil, uses current value.
-- @param height New height constraint to use.  If nil, uses current value.
function Geyser.Container:resize (width, height)
  self.width = width or self.width
  self.height = height or self.height
  self:set_constraints(self)
end

--- Sets the default font size for this window.
-- Will resizes this window if necessary to meet constraints.
-- @param fontSize The new font size to use.
function Geyser.Container:setFontSize (fontSize)
  if type(fontSize) ~= "number" then
    error("fontSize must be a number")
    return
  end
  self.fontSize = fontSize or self.fontSize
  self:set_constraints()
end

--- Sets all constraints (x, y, width, height) for this window.
-- @param cons Any Lua table that contains appropriate constraint entries.
function Geyser.Container:set_constraints (cons)
  cons = cons or self
  Geyser.set_constraints(self, cons, self.container)
  for k, v in pairs(self.windowList) do
    v:set_constraints(v)
  end
end

--- Flashes a white box over the dimensions of this container.
-- This is very useful to see where a container actually is if you've
-- forgotten its details.
-- @param time Time in seconds to flash for, default is 1.0s.
function Geyser.Container:flash (time)
  local time = time or 1.0
  local x, y, width, height = self.get_x(), self.get_y(), self.get_width(), self.get_height()
  local name = self.name .. "_dimensions_flash"
  createLabel(self.windowname ,name, x, y, width, height, 1)
  resizeWindow(name, width, height)
  moveWindow(name, x, y)
  setBackgroundColor(name, 190, 190, 190, 128)
  enableClickthrough(name)
  showWindow(name)
  tempTimer(time, "hideWindow(\"" .. name .. "\")")
end

Geyser.Container.parent = Geyser.Container -- I'm my own grandpa too!

-- Someone has to be the root!
setmetatable(Geyser.Container, Geyser)

--- Constructor for containers.
-- This function creates a new container/window
-- @param cons Any Lua table that contains appropriate constraint entries.
--             Include any parameter such as name or fontSize in cons
--             that are to be used for the new window.
function Geyser.Container:new(cons, container)
  -- create new table for the container and copy over constraints
  local me = Geyser.copyTable(cons)

  -- enforce a default type, name and parent
  me.type = me.type or "container"
  me.name = me.name or Geyser.nameGen()
  me.windowList = {}
  me.windows = {}
  --pass the given hidden/auto_hidden values for add2
  if me.useAdd2 == true or (container and container.useAdd2) then
    me.hidden = me.hidden or false
    me.auto_hidden = me.auto_hidden or false
  else
    me.hidden = false
    me.auto_hidden = false
  end
  -- Set the metatable.
  setmetatable(me, self)
  self.__index = self

  -- If we're not not a class definition then add to a controlling
  -- container.
  if not string.find(me.name, ".*Class") then
    -- If passed in a container, add me to that container
    if container then
      if me.useAdd2 then
        container:add2(me)
      else
        container:add(me)
      end
    else
      -- Else assume the root window is my container
      if me.useAdd2 then
        Geyser:add2(me)
      else
        Geyser:add(me)
      end
      container=Geyser
    end
   --Create Root-Container for UserWindow and add Children
   if (container == Geyser) and (me.windowname) and (me.windowname ~= "main") then
        container = Geyser.Container:new({name=me.windowname.."Container", type = "userwindow", x=0, y=0, width="100%", height="100%"})
        if me.useAdd2 then
          container:add2(me)
        else
          container:add(me)
        end
        container.get_width = function()
            return getUserWindowSize(me.windowname)
        end
        container.get_height = function()
            local w, h = getUserWindowSize(me.windowname)
            return h
        end
    end
  end

  --print("New in " .. self.name .. " : " .. me.name)
  return me
end

--- Overridden constructor to use add2
function Geyser.Container:new2 (cons, container)
  cons = cons or {}
  cons.useAdd2 = true
  local me = self:new(cons, container)
  return me
end
