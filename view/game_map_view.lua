-- map view of the colonies
GameMapView = {
  viewport = {},
  mapView = {}
}

function GameMapView:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  o.viewport = Viewport:new({ map=o.map, tileset=o.tileset, entityManager=o.entityManager })
  -- todo : subscribe to bus

  return o
end

function GameMapView:subscribe(bus)
  bus:subscribe("selection.selected", self, GameMapView.onEntitySelected)
  bus:subscribe("selection.deselected", self, GameMapView.onEntityDeselected)
end

function GameMapView:resize(w, h)
  self.viewport:resize(w, h)
end

function GameMapView:update(dt)
  local deltax, deltay = 0, 0
  -- Note to self: using love.keyboard.isDown because keypressed (as used below)
  -- doesn't work quite with repeated keys for some reason.
  if love.keyboard.isDown("a") then
    deltax = -4
  end
  if love.keyboard.isDown("d") then
    deltax = 4
  end
  if love.keyboard.isDown("w") then
    deltay = -4
  end
  if love.keyboard.isDown("s") then
    deltay = 4
  end
  if deltax ~= 0 or deltay ~= 0 then
    self.viewport:moveBy(deltax, deltay)
  end
end

function GameMapView:mousemoved(x,y)
  local posx, posy = self.viewport:screenToMap(x, y)
  if posx == self.lastx and posy == self.lasty then
    return
  end

  self.lastx = posx
  self.lasty = posy

  local tile = map:getAt(posAt(posx, posy))
  print(("Mouse over %d/%d: %s"):format(posx, posy, tile.terrain.title))
  print(pretty.dump(tile))
end

function GameMapView:keypressed(key, scancode, isrepeat)
  if scancode == 'escape' then
    -- TODO shouldn't just quit here, bring up menu or something
    love.event.quit()
  end
  if scancode == 'b' then
    -- TODO check return value?
    -- TODO should we just post an event if it can't be done?
    self.control:foundColony()
  end
  if scancode == 'c' then
    self:centerOnSelected()
  end
  if scancode == ',' then
    self.selectionManager:selectPrevIdle()
    self:centerOnSelected()
  end
  if scancode == '.' then
    self.selectionManager:selectNextIdle()
    self:centerOnSelected()
  end
  if scancode == 'return' then
    self:handleEndTurn()
  end
  if scancode == 'space' then
    self:doNothing()
  end
end

function GameMapView:mousereleased(x, y, button, istouch)
  local posx, posy = self.viewport:screenToMap(x, y)
  print("GameMapView:mousereleased", x, y, button, istouch)
  if button == 1 then
    -- TODO might run this through player control
    self.bus:fire("viewport.clicked", {button=button, x=posx, y=posy})
  elseif button == 2 then
    if self.selected then
      local entity = self.selected

      local pos = entity.position
      local dx = math.abs(pos.x - posx)
      local dy = math.abs(pos.y - posy)
      local distance = math.sqrt((dx*dx) + (dy*dy))

      self.control:issueCommand(self.selectedID, {action='move', destination=posAt(posx, posy), path={length=distance}})
    end
  end
end

function GameMapView:draw()
  local viewport = self.viewport
  viewport:draw()

  -- TODO global dependency on mousePosition
  local tile = mapView:getAt(mousePosition)
  local explored = mapView:isExplored(mousePosition)
  local tileMap = map:getAt(mousePosition)
  love.graphics.setColor(0, 0, 0)
  love.graphics.rectangle('fill', 600, 520, 200, 50)
  love.graphics.setColor(255, 255, 255)
  love.graphics.print(("Mouse: %d/%d"):format(mousePosition.x, mousePosition.y), 600, 520)
  love.graphics.print(("%s"):format(tile.terrain.title, explored), 600, 535)
  love.graphics.print(("Turn: %d Player: %s"):format(game.turn + 1, game:currentPlayer().name), 600, 550)
  if selectionManager.selected then
    local comps = entityManager:get(selectionManager.selected)
    if comps.action then
      local current = "-no orders-"
      if comps.action.current then
        current = comps.action.current.action
      end
      love.graphics.print(("%d/%d %s"):format(comps.action.points.left, comps.action.points.max, current), 600, 580)
    end

    local desc = ""
    if comps.colonist then
      desc = comps.colonist.profession.title
    end

    love.graphics.print(("[%d] %s, owner: %s"):format(selectionManager.selected, desc, comps.owner.id), 600, 565)
  end
end

function GameMapView:centerOnSelected()
  if not self.selected then return end
  if not self.selected.position then
    print("can't center on something without a position")
    return
  end

  self.viewport:center(self.selected.position)
end

function GameMapView:handleEndTurn()
  local predicate = function(comp)
    return comp.active and comp.points.left > 0
  end
  -- TODO game map view doesn't know about players... maybe that should
  -- live in the player control
  -- local entities = self.entityManager:getComponentsByType(ownedBy(self.player), {action=predicate}, position, selectable)

  -- for id, comps in pairs(entities) do
    -- self.selectionManager:select(id)
    -- self:centerOnSelected()
    -- if (#comps.action.queue) > 0 or comps.action.current then
      -- self.control:simulate(id)
      -- return
    -- else
      -- return
    -- end
  -- end

  self.control:endTurn()
end

function GameMapView:doNothing()
  if not self.selected then return end
  self.control:issueCommand(self.selectedID, {action='nothing'})
end

function GameMapView:onEntitySelected(e)
  self.selectedID = e.id
  self.selected = self.entityManager:get(e.id)
end

function GameMapView:onEntityDeselected(e)
  self.selectedID = nil
  self.selected = nil
end

