local utils = {}

--- Get distance between two points
---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function utils.getDistance(x1, y1, x2, y2)
    local horizontal_distance = x1 - x2
    local vertical_distance = y1 - y2

    local a = horizontal_distance ^ 2
    local b = vertical_distance ^ 2

    local c = a + b
    local distance = math.sqrt(c)

    return distance
end

--- Return random float between -1 and 1
---@return number
function utils.randFloat()
	return love.math.random() * 2 - 1
end

return utils