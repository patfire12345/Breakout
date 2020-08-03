--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]

function PlayState:init()
    self.inPlay2 = false
    self.inPlay3 = false
    self.PowerinPlay = false
    self.BlockedinPlay = false
    self.notBlocked = false
end

function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.level = params.level

    self.recoverPoints = 5000

    self.powerup = params.powerup
    self.blockedpower = params.blockedpower

    self.ball2 = params.ball2
    self.ball3 = params.ball3

    -- give ball random starting velocity
    self.ball.dx = math.random(-200, 200)
    self.ball.dy = math.random(-50, -60)

    -- give ball random starting velocity
    self.ball2.dx = math.random(-200, 200)
    self.ball2.dy = math.random(-50, -60)

    -- give ball random starting velocity
    self.ball3.dx = math.random(-200, 200)
    self.ball3.dy = math.random(-50, -60)
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    if self.score > 500 then
        self.PowerinPlay = true
    end

    if self.score > 1000 then
        self.BlockedinPlay = true
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    self.ball:update(dt)

    if self.inPlay2 then
        self.ball2:update(dt)
    end

    if self.inPlay3 then
        self.ball3:update(dt)
    end

    if self.PowerinPlay then
        self.powerup:update(dt)
    end

    if self.BlockedinPlay then
        self.blockedpower:update(dt)
    end

    function collidePaddle(ball,open)
        -- raise ball above paddle in case it goes below it, then reverse dy
        ball.y = self.paddle.y - 8
        ball.dy = -ball.dy

        --
        -- tweak angle of bounce based on where it hits the paddle
        --

        -- if we hit the paddle on its left side while moving left...
        if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
            ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
        
        -- else if we hit the paddle on its right side while moving right...
        elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
            ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
        end

        if open then
            gSounds['paddle-hit']:play()
        end
    end

    if self.ball:collides(self.paddle) then
        collidePaddle(self.ball,true)
    end

    if self.ball2:collides(self.paddle) then
        collidePaddle(self.ball2,self.inPlay2)
    end

    if self.ball3:collides(self.paddle) then
        collidePaddle(self.ball3,self.inPlay3)
    end

    if self.powerup:collides(self.paddle) then
        self.inPlay2 = true
        self.inPlay3 = true
        self.PowerinPlay = false
    end

    if self.blockedpower:collides(self.paddle) then
        self.BlockedinPlay = false
        self.notBlocked = true
    end

    function collideBrick(ball,brick)
        if self.notBlocked == true then
            brick.power = true
        end

        -- add to score
        if brick.tier == -1 and brick.power then
            self.score = self.score + 10000
        elseif brick.tier == -1 then 
            self.score = self.score
        else
            self.score = self.score + (brick.tier * 200 + brick.color * 25)
        end
        
        self.paddle:scoreUpdate(self.score)

        -- trigger the brick's hit function, which removes it from play
        brick:hit()

        -- if we have enough points, recover a point of health
        if self.score > self.recoverPoints then
            -- can't go above 3 health
            self.health = math.min(3, self.health + 1)

            -- multiply recover points by 2
            self.recoverPoints = math.min(100000, self.recoverPoints * 2)

            self.paddle:healthLoss(self.health)

            -- play recover sound effect
            gSounds['recover']:play()
        end

        -- go to our victory screen if there are no more bricks left
        if self:checkVictory() then
            gSounds['victory']:play()

            gStateMachine:change('victory', {
                level = self.level,
                paddle = self.paddle,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                ball = self.ball,
                recoverPoints = self.recoverPoints
            })
        end

        --
        -- collision code for bricks
        --
        -- we check to see if the opposite side of our velocity is outside of the brick;
        -- if it is, we trigger a collision on that side. else we're within the X + width of
        -- the brick and should check to see if the top or bottom edge is outside of the brick,
        -- colliding on the top or bottom accordingly 
        --

        -- left edge; only check if we're moving right, and offset the check by a couple of pixels
        -- so that flush corner hits register as Y flips, not X flips
        if ball.x + 2 < brick.x and ball.dx > 0 then
            
            -- flip x velocity and reset position outside of brick
            ball.dx = -ball.dx
            ball.x = brick.x - 8
        
        -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
        -- so that flush corner hits register as Y flips, not X flips
        elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
            
            -- flip x velocity and reset position outside of brick
            ball.dx = -ball.dx
            ball.x = brick.x + 32
        
        -- top edge if no X collisions, always check
        elseif ball.y < brick.y then
            
            -- flip y velocity and reset position outside of brick
            ball.dy = -ball.dy
            ball.y = brick.y - 8
        
        -- bottom edge if no X collisions or top collision, last possibility
        else
            
            -- flip y velocity and reset position outside of brick
            ball.dy = -ball.dy
            ball.y = brick.y + 16
        end

        -- slightly scale the y velocity to speed up the game, capping at +- 150
        if math.abs(ball.dy) < 150 then
            ball.dy = ball.dy * 1.02
        end
    end

    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do
        -- only check collision if we're in play
        if brick.inPlay and self.ball:collides(brick) then
            collideBrick(self.ball,brick)
            -- only allow colliding with one brick, for corners
            break
        end

        if brick.inPlay and self.ball2:collides(brick) then
            collideBrick(self.ball2,brick)
            break
        end

        if brick.inPlay and self.ball3:collides(brick) then 
            collideBrick(self.ball3,brick)
            break
        end
    end

    -- if ball goes below bounds, revert to serve state and decrease health
    if self.ball.y >= VIRTUAL_HEIGHT then
        self.health = self.health - 1
        self.paddle:healthLoss(self.health)
        gSounds['hurt']:play()

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints
            })
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    self.ball:render()

    if self.inPlay2 then
        self.ball2:render()
    end

    if self.inPlay3 then
        self.ball3:render()
    end

    if self.PowerinPlay then
        self.powerup:render()
    end

    if self.BlockedinPlay then
        self.blockedpower:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end