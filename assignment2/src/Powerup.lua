Powerup = Class{}

function Powerup:init(skin)
    self.width = 8
    self.height = 8

    self.x = VIRTUAL_WIDTH / 2 - math.random(-50,50)
    self.y = VIRTUAL_HEIGHT/2 - 100

    self.dy = 10
    self.dx = 0

    self.skin = skin

end

function Powerup:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end



function Powerup:update(dt)
    self.y = self.y + self.dy * dt
end

function Powerup:render()
    love.graphics.draw(gTextures['main'], gFrames['powerup'][self.skin],
        self.x, self.y)
end