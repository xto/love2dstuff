Tileset = { tileW, tileH }

function Tileset:load(filename)
  local tileset = love.graphics.newImage(filename)

  tileW, tileH = 32,32
  local tilesetW, tilesetH = tileset:getWidth(), tileset:getHeight()

  self['tileset'] = tileset
  self['tiles'] = {}
  self['tiles'][1] = love.graphics.newQuad(0, 0, tileW, tileH, tilesetW, tilesetH)
  self['tiles'][2] = love.graphics.newQuad(tileW, 0, tileW, tileH, tilesetW, tilesetH)
  self['tiles'][3] = love.graphics.newQuad(0, tileH, tileW, tileH, tilesetW, tilesetH)

  local units = love.graphics.newImage("assets/units.png")
  local unitw, unith = units:getWidth(), units:getHeight()

  self.units = units
  self.unit = {}
  self.unit['caravel'] = love.graphics.newQuad(3*60, 60, 60, 60, unitw, unith)
end

function Tileset:draw(x, y, id)
  love.graphics.draw(self['tileset'], self['tiles'][id], x, y)
end

function Tileset:tileSize()
  return tileW, tileH
end

