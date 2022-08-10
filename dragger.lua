local dragger = {
  X = 0,
  Y = 0,
  savedX = 0,
  savedY = 0,
}

local wasActive = false

---@param isActive boolean
function dragger.update(isActive)
  local mouseX, mouseY = love.mouse.getPosition()
  if isActive ~= wasActive then
    if isActive then
      dragger.savedX = dragger.savedX - mouseX
      dragger.savedY = dragger.savedY - mouseY
    else
      dragger.savedX = dragger.X
      dragger.savedY = dragger.Y
    end
    wasActive = isActive
  end

  if isActive then
    dragger.X = mouseX + dragger.savedX
    dragger.Y = mouseY + dragger.savedY
  end
end

return dragger