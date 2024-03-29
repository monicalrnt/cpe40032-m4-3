--[[
   CMPE40032
    Candy Crush Clone (Match 3 Game)

    -- PlayState Class --



    State in which we can actually play, moving around a grid cursor that
    can swap two tiles; when two tiles make a legal swap (a swap that results
    in a valid match), perform the swap and destroy all matched tiles, adding
    their values to the player's point score. The player can continue playing
    until they exceed the number of points needed to get to the next level
    or until the time runs out, at which point they are brought back to the
    main menu or the score entry menu if they made the top 10.
]]

PlayState = Class{__includes = BaseState}

function PlayState:init()
    -- start our transition alpha at full, so we fade in
    self.transitionAlpha = 255

    -- position in the grid which we're highlighting
    self.boardHighlightX = 0
    self.boardHighlightY = 0

    -- timer used to switch the highlight rect's color
    self.rectHighlighted = false

    -- flag to show whether we're able to process input (not swapping or clearing)
    self.canInput = true

    -- tile we're currently highlighting (preparing to swap)
    self.highlightedTile = nil

    self.score = 0
    self.timer = 60

    -- set our Timer class to turn cursor highlight on and off
    Timer.every(0.5, function()
        self.rectHighlighted = not self.rectHighlighted
    end)

    -- subtract 1 from timer every second
    Timer.every(1, function()
        self.timer = self.timer - 1

        -- play warning sound on timer if we get low
        if self.timer <= 5 then
            gSounds['clock']:play()
        end
    end)
end

function PlayState:enter(params)
    -- grab level # from the params we're passed
    self.level = params.level
    
    -- spawn a board and place it toward the right
    self.board = params.board or Board(VIRTUAL_WIDTH - 272, 16)

    -- grab score from params if it was passed
    self.score = params.score or 0

    -- score we have to reach to get to the next level
    self.scoreGoal = self.level * 1.25 * 1000
    while not self:matchExists() do
        self:shuffle()
    end
end
function PlayState:matchExists()
	for i=1,8,1 do
		for j=1,8,1 do
			if i-1>=1 then
				local temp1=self.board.tiles[i][j]
				local temp2=self.board.tiles[i-1][j]
				if self:tileswap(self.board.tiles[i][j],self.board.tiles[i-1][j]) then
					self:tileswap(temp1,temp2)
					return true
				end
				self:tileswap(temp1,temp2)
			end
			if i+1<=8 then
				local temp1=self.board.tiles[i][j]
				local temp2=self.board.tiles[i+1][j]
				if self:tileswap(self.board.tiles[i][j],self.board.tiles[i+1][j]) then
					self:tileswap(temp1,temp2)
					return true
				end
				self:tileswap(temp1,temp2)
			end
			if j-1>=1 then
				local temp1=self.board.tiles[i][j]
				local temp2=self.board.tiles[i][j-1]
				if self:tileswap(self.board.tiles[i][j],self.board.tiles[i][j-1]) then
					self:tileswap(temp1,temp2)
					return true
				end
				self:tileswap(temp1,temp2)
			end
			if j+1<=8 then
				local temp1=self.board.tiles[i][j]
				local temp2=self.board.tiles[i][j+1]
				if self:tileswap(self.board.tiles[i][j],self.board.tiles[i][j+1]) then
					self:tileswap(temp1,temp2)
					return true
				end
				self:tileswap(temp1,temp2)
			end
		end
	end
	return false
end

function PlayState:shuffle()

    for i=1,20,1 do
        local x1=math.random(1,16)
        local y1=math.random(1,16)
        local x2=math.random(1,16)
        local y2=math.random(1,16)
        local temp1=self.board.tiles[x1][y1]
        local temp2=self.board.tiles[x2][y2]
        self:tileswap(temp1,temp2)
    end
    
end

function PlayState:update(dt)
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

    -- go back to start if time runs out
    if self.timer <= 0 then
        -- clear timers from prior PlayStates
        Timer.clear()

        gSounds['game-over']:play()

        gStateMachine:change('game-over', {
            score = self.score
        })
    end

    -- go to next level if we surpass score goal
    if self.score >= self.scoreGoal then
        -- clear timers from prior PlayStates
        -- always clear before you change state, else next state's timers
        -- will also clear!
        Timer.clear()

        gSounds['next-level']:play()

        -- change to begin game state with new level (incremented)
        gStateMachine:change('begin-game', {
            level = self.level + 1,
            score = self.score
        })
    end

    if self.canInput then
        -- move cursor around based on bounds of grid, playing sounds
        if love.keyboard.wasPressed('up') then
            self.boardHighlightY = math.max(0, self.boardHighlightY - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('down') then
            self.boardHighlightY = math.min(7, self.boardHighlightY + 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('left') then
            self.boardHighlightX = math.max(0, self.boardHighlightX - 1)
            gSounds['select']:play()
        elseif love.keyboard.wasPressed('right') then
            self.boardHighlightX = math.min(7, self.boardHighlightX + 1)
            gSounds['select']:play()
        end

        -- if we've pressed enter, to select or deselect a tile...
        if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
            -- if same tile as currently highlighted, deselect
            local x = self.boardHighlightX + 1
            local y = self.boardHighlightY + 1

            -- if nothing is highlighted, highlight current tile
            if not self.highlightedTile then
                self.highlightedTile = self.board.tiles[y][x]

            -- if we select the position already highlighted, remove highlight
            elseif self.highlightedTile == self.board.tiles[y][x] then
                self.highlightedTile = nil

            -- if the difference between X and Y combined of this highlighted tile
            -- vs the previous is not equal to 1, also remove highlight
            elseif math.abs(self.highlightedTile.gridX - x) + math.abs(self.highlightedTile.gridY - y) > 1 then
                gSounds['error']:play()
                self.highlightedTile = nil
            else
              

                temp1=self.highlightedTile
				temp2=self.board.tiles[y][x]
				if not self:tileswap(self.highlightedTile,self.board.tiles[y][x]) then
					Timer.tween(0.3, {
						[temp1] = {x = temp2.x, y = temp2.y},
						[temp2] = {x = temp1.x, y = temp1.y}
                    })
					-- once the swap is finished, we can tween falling blocks as needed
                    :finish(function()
                        if not self:calculateMatches() then
                            self:tileswap(temp1,temp2)
                            Timer.tween(0.3, {
                                [temp1] = {x = temp2.x, y = temp2.y},
                                [temp2] = {x = temp1.x, y = temp1.y}
                            })
                        end
                        self:calculateMatches(0)
                        
					end)
					self.canInput=true
				else
                -- tween coordinates between the two so they swap
					Timer.tween(0.3, {
						[temp1] = {x = temp2.x, y = temp2.y},
						[temp2] = {x = temp1.x, y = temp1.y}
					})

                
                
                    :finish(function()
                        self:calculateMatches()
                    end)
                    while not self:matchExists() do
                        self.canInput=false
                        self:shuffle()
                    end
                end
            end
        end
    end
    -- (Jsh)whenever keyboard is not in use
    if not self.isKeyboard then
    
        local mousePointerX, mousePointerY = push:toGame(love.mouse.getPosition())

        
        local mousePointerX = mousePointerX - (VIRTUAL_WIDTH - 272)
        local mousePointerY = mousePointerY - 16

    -- (Jsh)getting the position of the mouse pointer
        if mousePointerX >= 0 and mousePointerX <= 255
        and mousePointerY >= 0 and mousePointerY <= 255 then

        -- (Jsh)position of the mouse pointer renders the red highlight box in tiles 
            local mousePointerGridX = math.floor(mousePointerX / 32)
            local mousePointerGridY = math.floor(mousePointerY / 32)

            self.boardHighlightX = mousePointerGridX
            self.boardHighlightY = mousePointerGridY
        end
    end

    -- (Jsh)when left mouse button is pressed. Same code when the enter and return button is pressed (line 120)
    function love.mousepressed(mouse_x, mouse_y, button)
        if button == 1 then
            self.isKeyboard = false
            local x = self.boardHighlightX + 1
            local y = self.boardHighlightY + 1
            if not self.highlightedTile then
                self.highlightedTile = self.board.tiles[y][x]
            elseif self.highlightedTile == self.board.tiles[y][x] then
                    self.highlightedTile = nil
            elseif math.abs(self.highlightedTile.gridX - x) + math.abs(self.highlightedTile.gridY - y) > 1 then
                    gSounds['error']:play()
                    self.highlightedTile = nil
            else                    
                local tempX = self.highlightedTile.gridX
                local tempY = self.highlightedTile.gridY
                local newTile = self.board.tiles[y][x]
    
                self.highlightedTile.gridX = newTile.gridX
                self.highlightedTile.gridY = newTile.gridY
                newTile.gridX = tempX
                newTile.gridY = tempY
                    
                self.board.tiles[self.highlightedTile.gridY][self.highlightedTile.gridX] =
                self.highlightedTile
    
                self.board.tiles[newTile.gridY][newTile.gridX] = newTile
    
                Timer.tween(0.1, {
                        [self.highlightedTile] = {x = newTile.x, y = newTile.y},
                        [newTile] = {x = self.highlightedTile.x, y = self.highlightedTile.y}
                    })
                    
                    :finish(function()
                        self:calculateMatches()
                end)
            end
        

        end
    end

    Timer.update(dt)
end

function PlayState:tileswap(Tile1,Tile2)
	local tempX =Tile1.gridX
    local tempY =Tile1.gridY
    Tile1.gridX = Tile2.gridX
    Tile1.gridY = Tile2.gridY
    Tile2.gridX = tempX
    Tile2.gridY = tempY
    -- swap tiles in the tiles table
    self.board.tiles[Tile1.gridY][Tile1.gridX] =Tile1
	self.board.tiles[Tile2.gridY][Tile2.gridX] =Tile2
	return self:calculateMatches(1)
end
--[[
    Calculates whether any matches were found on the board and tweens the needed
    tiles to their new destinations if so. Also removes tiles from the board that
    have matched and replaces them with new randomized tiles, deferring most of this
    to the Board class.
]]
function PlayState:calculateMatches(param)
    self.highlightedTile = nil

    -- if we have any matches, remove them and tween the falling blocks that result
    local matches = self.board:calculateMatches()
    if param==1 then
		return matches
	end
    if matches then
        gSounds['match']:stop()
        gSounds['match']:play()

        -- add score for each match
        for k, match in pairs(matches) do
            self.score = self.score + #match * 50
			self.timer = self.timer + #match
        end

        -- remove any tiles that matched from the board, making empty spaces
        self.board:removeMatches()

        -- gets a table with tween values for tiles that should now fall
        local tilesToFall = self.board:getFallingTiles()

        -- tween new tiles that spawn from the ceiling over 0.25s to fill in
        -- the new upper gaps that exist
        Timer.tween(0.25, tilesToFall):finish(function()
            
            -- recursively call function in case new matches have been created
            -- as a result of falling blocks once new blocks have finished falling
            self:calculateMatches(param)
        end)
        -- if no matches, we can continue playing
    else
        self.canInput = true
    end
end

function PlayState:render()
    -- render board of tiles
    self.board:render()

    -- render highlighted tile if it exists
    if self.highlightedTile then
        -- multiply so drawing white rect makes it brighter
        love.graphics.setBlendMode('add')

        love.graphics.setColor(255, 255, 255, 96)
        love.graphics.rectangle('fill', (self.highlightedTile.gridX - 1) * 32 + (VIRTUAL_WIDTH - 272),
            (self.highlightedTile.gridY - 1) * 32 + 16, 32, 32, 4)

        -- back to alpha
        love.graphics.setBlendMode('alpha')
    end

    -- render highlight rect color based on timer
    if self.rectHighlighted then
        love.graphics.setColor(217, 87, 99, 255)
    else
        love.graphics.setColor(172, 50, 50, 255)
    end

    -- draw actual cursor rect
    love.graphics.setLineWidth(4)
    love.graphics.rectangle('line', self.boardHighlightX * 32 + (VIRTUAL_WIDTH - 272),
        self.boardHighlightY * 32 + 16, 32, 32, 4)

    -- GUI text
    love.graphics.setColor(56, 56, 56, 234)
    love.graphics.rectangle('fill', 16, 16, 186, 116, 4)

    love.graphics.setColor(99, 155, 255, 255)
    love.graphics.setFont(gFonts['medium'])
    love.graphics.printf('Level: ' .. tostring(self.level), 20, 24, 182, 'center')
    love.graphics.printf('Score: ' .. tostring(self.score), 20, 52, 182, 'center')
    love.graphics.printf('Goal : ' .. tostring(self.scoreGoal), 20, 80, 182, 'center')
    love.graphics.printf('Timer: ' .. tostring(self.timer), 20, 108, 182, 'center')
end