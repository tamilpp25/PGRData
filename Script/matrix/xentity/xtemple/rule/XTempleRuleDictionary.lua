local XTempleEnumConst = require("XEntity/XTemple/XTempleEnumConst")

local dictionary = {}

--每存在一个与【%s】相邻的【%s】地块，可获得【%s】分
dictionary[1001] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(2)) then
                    if not self:IsGridExecuted(grid) then
                        local neighbourGrids = map:FindNeighbourGrids(grid)
                        if self:FindInGrids(neighbourGrids, self:GetParamsGridType(1)) then
                            score = score + self:GetRewardScore()
                            self:SetGridExecuted(grid)
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local grid2 = self:GetGridNameByType(self._Params[2])
        local score = self:GetRewardScore()
        return string.format(text, grid1, grid2, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(2, ruleTable)
    end,
}

--每存在一个同时与【%s】【%s】相邻的【%s】地块，可获得【%s】分
dictionary[1002] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(3)) then
                    if not self:IsGridExecuted(grid) then
                        local neighbourGrids = map:FindNeighbourGrids(grid)
                        if self:FindInGrids(neighbourGrids, self:GetParamsGridType(1))
                                and self:FindInGrids(neighbourGrids, self:GetParamsGridType(2)) then
                            score = score + self:GetRewardScore()
                            self:SetGridExecuted(grid)
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local grid2 = self:GetGridNameByType(self._Params[2])
        local grid3 = self:GetGridNameByType(self._Params[3])
        local score = self:GetRewardScore()
        return string.format(text, grid1, grid2, grid3, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(3, ruleTable)
    end,
}

--每存在一个同时与【%s】【%s】【%s】相邻的【%s】地块，可获得【%s】分
dictionary[1003] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(4)) then
                    if not self:IsGridExecuted(grid) then
                        local neighbourGrids = map:FindNeighbourGrids(grid)
                        if self:FindInGrids(neighbourGrids, self:GetParamsGridType(1))
                                and self:FindInGrids(neighbourGrids, self:GetParamsGridType(2))
                                and self:FindInGrids(neighbourGrids, self:GetParamsGridType(3))
                        then
                            score = score + self:GetRewardScore()
                            self:SetGridExecuted(grid)
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local grid2 = self:GetGridNameByType(self._Params[2])
        local grid3 = self:GetGridNameByType(self._Params[3])
        local grid4 = self:GetGridNameByType(self._Params[4])
        local score = self:GetRewardScore()
        return string.format(text, grid1, grid2, grid3, grid4, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(4, ruleTable)
    end,
}

--每存在一个同时与【%s】【%s】【%s】【%s】相邻的【%s】地块，可获得【%s】分
dictionary[1004] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(5)) then
                    if not self:IsGridExecuted(grid) then
                        local neighbourGrids = map:FindNeighbourGrids(grid)
                        if self:FindInGrids(neighbourGrids, self._Params[1])
                                and self:FindInGrids(neighbourGrids, self:GetParamsGridType(2))
                                and self:FindInGrids(neighbourGrids, self:GetParamsGridType(3))
                                and self:FindInGrids(neighbourGrids, self:GetParamsGridType(4))
                        then
                            score = score + self:GetRewardScore()
                            self:SetGridExecuted(grid)
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local grid2 = self:GetGridNameByType(self._Params[2])
        local grid3 = self:GetGridNameByType(self._Params[3])
        local grid4 = self:GetGridNameByType(self._Params[4])
        local grid5 = self:GetGridNameByType(self._Params[5])
        local score = self:GetRewardScore()
        return string.format(text, grid1, grid2, grid3, grid4, grid5, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(5, ruleTable)
    end,
}

--每存在一个不与【%s】相邻的【%s】地块，可获得【%s】分
dictionary[1005] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(2)) then
                    if not self:IsGridExecuted(grid) then
                        local neighbourGrids = map:FindNeighbourGrids(grid)
                        if not self:FindInGrids(neighbourGrids, self:GetParamsGridType(1)) then
                            score = score + self:GetRewardScore()
                            self:SetGridExecuted(grid)
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local grid2 = self:GetGridNameByType(self._Params[2])
        local score = self:GetRewardScore()
        return string.format(text, grid1, grid2, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(2, ruleTable)
    end,
}

--每存在一个被包围的【%s】地块，可获得【%s】分
dictionary[1006] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param grid XTempleGrid
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(1)) then
                    if not self:IsGridExecuted(grid) then
                        local neighbourGrids = map:FindNeighbourGrids(grid)
                        if self:IsSurroundBySomeGrids(neighbourGrids) then
                            score = score + self:GetRewardScore()
                            self:SetGridExecuted(grid)
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local score = self:GetRewardScore()
        return string.format(text, grid1, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(1, ruleTable)
    end,
}

--每存在一个与边缘线相邻的【%s】地块，可获得【%s】分
dictionary[1007] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param grid XTempleGrid
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(1)) then
                    if not self:IsGridExecuted(grid) then
                        if self:IsGridOnMapEdge(grid, map) then
                            score = score + self:GetRewardScore()
                            self:SetGridExecuted(grid)
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local score = self:GetRewardScore()
        return string.format(text, grid1, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(1, ruleTable)
    end,
}

--每存在一个不与边缘线相邻的【%s】地块，可获得【%s】分
dictionary[1008] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(1)) then
                    if not self:IsGridExecuted(grid) then
                        if not self:IsGridOnMapEdge(grid, map) then
                            score = score + self:GetRewardScore()
                            self:SetGridExecuted(grid)
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local score = self:GetRewardScore()
        return string.format(text, grid1, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(1, ruleTable)
    end,
}

--每存在一个被【%s】包围的【%s】地块，可获得【%s】分
dictionary[2001] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(2)) then
                    if not self:IsGridExecuted(grid) then
                        local neighbourGrids = map:FindNeighbourGrids(grid)
                        if self:IsSurroundByGrids1(neighbourGrids, self:GetParamsGridType(1)) then
                            score = score + self:GetRewardScore()
                            self:SetGridExecuted(grid)
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local grid2 = self:GetGridNameByType(self._Params[2])
        local score = self:GetRewardScore()
        return string.format(text, grid1, grid2, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(2, ruleTable)
    end,
}

--每存在一个被【%s】【%s】包围的【%s】地块，可获得【%s】分
dictionary[2002] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(3)) then
                    if not self:IsGridExecuted(grid) then
                        local neighbourGrids = map:FindNeighbourGrids(grid)
                        if self:IsSurroundByGrids2(neighbourGrids, self:GetParamsGridType(1), self:GetParamsGridType(2)) then
                            score = score + self:GetRewardScore()
                            self:SetGridExecuted(grid)
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local grid2 = self:GetGridNameByType(self._Params[2])
        local grid3 = self:GetGridNameByType(self._Params[3])
        local score = self:GetRewardScore()
        return string.format(text, grid1, grid2, grid3, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(3, ruleTable)
    end,
}

--每存在一个被【%s】【%s】【%s】包围的【%s】地块，可获得【%s】分
dictionary[2003] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(4)) then
                    if not self:IsGridExecuted(grid) then
                        local neighbourGrids = map:FindNeighbourGrids(grid)
                        if self:IsSurroundByGrids3(neighbourGrids, self:GetParamsGridType(1), self:GetParamsGridType(2), self:GetParamsGridType(3)) then
                            score = score + self:GetRewardScore()
                            self:SetGridExecuted(grid)
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local grid2 = self:GetGridNameByType(self._Params[2])
        local grid3 = self:GetGridNameByType(self._Params[3])
        local grid4 = self:GetGridNameByType(self._Params[4])
        local score = self:GetRewardScore()
        return string.format(text, grid1, grid2, grid3, grid4, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(4, ruleTable)
    end,
}

--每存在一个不与任意地块相邻的【%s】地块，可获得【%s】分
dictionary[2004] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(1)) then
                    if not self:IsGridExecuted(grid) then
                        local neighbourGrids = map:FindNeighbourGrids(grid)
                        if self:IsSurroundByEmpty(neighbourGrids) then
                            score = score + self:GetRewardScore()
                            self:SetGridExecuted(grid)
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local score = self:GetRewardScore()
        return string.format(text, grid1, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(1, ruleTable)
    end,
}

--每存在一个2*2的【%s】群落，可获得【%s】分
dictionary[3001] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(1)) then
                    if not self:IsGridExecuted(grid) then
                        -- 右上
                        local isMatch, grids = self:_IsGridsMatchSquare(x, y, map, self:GetParamsGridType(1), 2)
                        if isMatch and not self:IsGridsExecuted(grids) then
                            score = score + self:GetRewardScore()
                            self:SetGridsExecuted(grids)
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local score = self:GetRewardScore()
        return string.format(text, grid1, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(1, ruleTable)
    end,
}

--每存在一个3*3的【%s】群落，可获得【%s】分
dictionary[3002] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(1)) then
                    if not self:IsGridExecuted(grid) then
                        -- 右上
                        local isMatch, grids = self:_IsGridsMatchSquare(x, y, map, self:GetParamsGridType(1), 3)
                        if isMatch and not self:IsGridsExecuted(grids) then
                            score = score + self:GetRewardScore()
                            self:SetGridsExecuted(grids)
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local score = self:GetRewardScore()
        return string.format(text, grid1, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(1, ruleTable)
    end,
}

--每存在一个4*4的【%s】群落，可获得【%s】分
dictionary[3003] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param grid XTempleGrid
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(1)) then
                    if not self:IsGridExecuted(grid) then
                        -- 右上
                        local isMatch, grids = self:_IsGridsMatchSquare(x, y, map, self:GetParamsGridType(1), 4)
                        if isMatch and not self:IsGridsExecuted(grids) then
                            score = score + self:GetRewardScore()
                            self:SetGridsExecuted(grids)
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local score = self:GetRewardScore()
        return string.format(text, grid1, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(1, ruleTable)
    end,
}

--每存在一个5*5的【%s】群落，可获得【%s】分
dictionary[3004] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(1)) then
                    if not self:IsGridExecuted(grid) then
                        -- 右上
                        local isMatch, grids = self:_IsGridsMatchSquare(x, y, map, self:GetParamsGridType(1), 5)
                        if isMatch and not self:IsGridsExecuted(grids) then
                            score = score + self:GetRewardScore()
                            self:SetGridsExecuted(grids)
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local score = self:GetRewardScore()
        return string.format(text, grid1, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(1, ruleTable)
    end,
}

--每存在一个6*6的【%s】群落，可获得【%s】分
dictionary[3005] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(1)) then
                    if not self:IsGridExecuted(grid) then
                        -- 右上
                        local isMatch, grids = self:_IsGridsMatchSquare(x, y, map, self:GetParamsGridType(1), 6)
                        if isMatch and not self:IsGridsExecuted(grids) then
                            score = score + self:GetRewardScore()
                            self:SetGridsExecuted(grids)
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local score = self:GetRewardScore()
        return string.format(text, grid1, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(1, ruleTable)
    end,
}

--每存在一个由【%s】个或者【%s】个以上的【%s】地块组成的群落，可获得【%s】分
dictionary[4001] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(2)) then
                    if not self:IsGridExecuted(grid) then
                        local isMatch, grids = self:IsGridCommunity(grid, map, self:GetParamsGridType(1))
                        if isMatch and not self:IsGridsExecuted(grids) then
                            score = score + self:GetRewardScore()
                            self:SetGridsExecuted(grids)
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local amount = self._Params[1]
        local grid1 = self:GetGridNameByType(self._Params[2])
        local score = self:GetRewardScore()
        return string.format(text, amount, amount, grid1, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        local dropdownAmount, valueAmount = self:GetEditorAmountOptions()
        return {
            {
                DropDown = dropdownAmount,
                Value = valueAmount,
                Selected = self._OwnControl:GetDropdownValue(self._Params[1], valueAmount),
            },
            self:GetEditorOption4Grid(self._Params[2]) }
    end,
    KeyParams = 2,
}

--每存在一张【%s】地块，可获得【%s】分
dictionary[4002] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(1)) then
                    if not self:IsGridExecuted(grid) then
                        score = score + self:GetRewardScore()
                        self:SetGridExecuted(grid)
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local score = self:GetRewardScore()
        return string.format(text, grid1, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(1, ruleTable)
    end,
}

--每存在一个【%s】地块群落，可获得【%s】分
dictionary[4003] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(1)) then
                    if not self:IsGridExecuted(grid) then
                        local isMatch, grids = self:IsGridCommunity(grid, map)
                        if isMatch and not self:IsGridsExecuted(grids) then
                            score = score + self:GetRewardScore()
                            self:SetGridsExecuted(grids)
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local score = self:GetRewardScore()
        return string.format(text, grid1, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(1, ruleTable)
    end,
}

--【%s】群落与【%s】群落相邻，可获得【%s】分
dictionary[4004] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(1)) then
                    if not self:IsGridExecuted(grid) then
                        local isMatch, linkGrids = self:IsGridCommunity(grid, map)
                        if isMatch and not self:IsGridsExecuted(linkGrids) then
                            local neighbourGrids = map:FindNeighbourGrids(grid)
                            for i = 1, #neighbourGrids do
                                local neighbourGrid = neighbourGrids[i]
                                if neighbourGrid:IsType(self:GetParamsGridType(2))
                                        and self:IsGridCommunity(neighbourGrid, map) then
                                    score = score + self:GetRewardScore()
                                    self:SetGridsExecuted(linkGrids)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local grid2 = self:GetGridNameByType(self._Params[2])
        local score = self:GetRewardScore()
        return string.format(text, grid1, grid2, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(2, ruleTable)
    end,
    KeyParamsIndex = 1
}

--【%s】群落通过【%s】群落与【%s】群落相连，可获得【%s】分
dictionary[4005] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        if self._Params[1] == self._Params[2] or self._Params[1] == self._Params[3] or self._Params[2] == self._Params[3] then
            XLog.Error("[XTempleRule] rule is illegal", 4005)
            return 0
        end

        --todo by zlb violent force
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)

                local type1 = self:GetParamsGridType(1)
                if grid:IsType(type1) then
                    local isGridCommunity1, linkGrids1 = self:IsGridCommunity(grid, map)
                    if isGridCommunity1 and not self:IsGridsExecuted(linkGrids1) then

                        -- 下面的规则是 A -> {B B B ..} -> C, 所以有三层循环, 但是效率略低, 后期再考虑优化
                        for i = 1, #linkGrids1 do
                            local linkGrid1 = linkGrids1[i]
                            local neighbours1 = map:FindNeighbourGrids(linkGrid1)
                            for n = 1, #neighbours1 do
                                local neighbour1 = neighbours1[n]
                                if neighbour1:IsType(self:GetParamsGridType(2)) then
                                    local isGridCommunity2, linkGrids2 = self:IsGridCommunity(neighbour1, map)
                                    if isGridCommunity2 then
                                        for j = 1, #linkGrids2 do
                                            local neighbours2 = map:FindNeighbourGrids(linkGrids2[j])
                                            for k = 1, #neighbours2 do
                                                local neighbour2 = neighbours2[k]
                                                if neighbour2:IsType(self:GetParamsGridType(3)) and self:IsGridCommunity(neighbour2, map) then
                                                    -- todo by zlb 有空再想办法了
                                                    local isValid = false
                                                    for l = 1, #linkGrids1 do
                                                        local linkGrid = linkGrids1[l]
                                                        if not self:IsGridExecuted(linkGrid) then
                                                            isValid = true
                                                            break
                                                        end
                                                    end
                                                    if isValid then
                                                        score = score + self:GetRewardScore()
                                                    end
                                                    self:SetGridsExecuted(linkGrids1)
                                                    break
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local grid2 = self:GetGridNameByType(self._Params[2])
        local grid3 = self:GetGridNameByType(self._Params[3])
        local score = self:GetRewardScore()
        return string.format(text, grid1, grid2, grid3, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(3, ruleTable)
    end,
    KeyParamsIndex = 1
}

--每存在一个不与【%s】地块相邻的【%s】群落，可获得【%s】分
dictionary[4006] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(2)) then
                    if not self:IsGridExecuted(grid) then
                        local isMatch, linkGrids = self:IsGridCommunity(grid, map)
                        if isMatch and not self:IsGridsExecuted(linkGrids) then
                            local isBreak = false
                            for i = 1, #linkGrids do
                                local linkGrid = linkGrids[i]
                                local neighbourGrids = map:FindNeighbourGrids(linkGrid)
                                for i = 1, #neighbourGrids do
                                    local neighbourGrid = neighbourGrids[i]
                                    if neighbourGrid:IsType(self:GetParamsGridType(1)) then
                                        isBreak = true
                                        break
                                    end
                                end
                                if isBreak then
                                    break
                                end
                            end
                            if not isBreak then
                                score = score + self:GetRewardScore()
                                self:SetGridsExecuted(linkGrids)
                            end
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local grid2 = self:GetGridNameByType(self._Params[2])
        local score = self:GetRewardScore()
        return string.format(text, grid1, grid2, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(2, ruleTable)
    end,
}

--每存在一个【%s】地块相邻的【%s】群落，可获得【%s】分
dictionary[4007] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(2)) then
                    if not self:IsGridExecuted(grid) then
                        local isMatch, linkGrids = self:IsGridCommunity(grid, map)
                        if isMatch and not self:IsGridsExecuted(linkGrids) then
                            local neighbourGrids = map:FindNeighbourGrids(grid)
                            for i = 1, #neighbourGrids do
                                local neighbourGrid = neighbourGrids[i]
                                if neighbourGrid:IsType(self:GetParamsGridType(1)) then
                                    score = score + self:GetRewardScore()
                                    self:SetGridsExecuted(linkGrids)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local grid2 = self:GetGridNameByType(self._Params[2])
        local score = self:GetRewardScore()
        return string.format(text, grid1, grid2, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(2, ruleTable)
    end,
}

--每存在一个与3种或者3种以上的地块相邻的【%s】群落，可获得【%s】分
dictionary[4008] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        local targetAmount = 3
        local gridType1 = self:GetParamsGridType(1)
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(gridType1) then
                    if not self:IsGridExecuted(grid) then
                        local isMatch, linkGrids = self:IsGridCommunity(grid, map)
                        if isMatch and not self:IsGridsExecuted(linkGrids) then
                            local typeAmount = 0
                            local typeDict = { [gridType1] = true }
                            for i = 1, #linkGrids do
                                local linkGrid = linkGrids[i]
                                local neighbours = map:FindNeighbourGrids(linkGrid)
                                for j = 1, #neighbours do
                                    local neighbour = neighbours[j]
                                    if not neighbour:IsEmpty() then
                                        local type = neighbour:GetType()
                                        if not typeDict[type] then
                                            typeAmount = typeAmount + 1
                                            typeDict[type] = true
                                            if typeAmount >= targetAmount then
                                                break
                                            end
                                        end
                                    end
                                end
                            end
                            if typeAmount >= targetAmount then
                                score = score + self:GetRewardScore()
                                self:SetGridsExecuted(linkGrids)
                            end
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local score = self:GetRewardScore()
        return string.format(text, grid1, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(1, ruleTable)
    end,
    KeyParams = 1,
}

--每存在一个与【%s】群落相邻的【%s】地块，可获得【%s】分
dictionary[4009] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        local grid1 = self:GetParamsGridType(1)
        local grid2 = self:GetParamsGridType(2)
        if grid1 == grid2 then
            for y = 1, map:GetRowAmount() do
                for x = 1, map:GetColumnAmount() do
                    ---@type XTempleGrid
                    local grid = map:GetGrid(x, y)
                    if grid:IsType(grid1) then
                        if not self:IsGridExecuted(grid) then
                            local isGridCommunity, linkGrids = self:IsGridCommunity(grid, map)
                            if isGridCommunity then
                                local amount = #linkGrids
                                score = score + (amount - 2) * self:GetRewardScore()
                                self:SetGridsExecuted(linkGrids)
                            end
                        end
                    end
                end
            end
        else
            ---@type table<XTempleGrid,boolean>
            local communityGrids = {}
            for y = 1, map:GetRowAmount() do
                for x = 1, map:GetColumnAmount() do
                    ---@type XTempleGrid
                    local grid = map:GetGrid(x, y)
                    if grid:IsType(grid1) then
                        if not communityGrids[grid1] then
                            local isGridCommunity, linkGrids = self:IsGridCommunity(grid, map)
                            if isGridCommunity then
                                for i = 1, #linkGrids do
                                    local linkGrid = linkGrids[i]
                                    communityGrids[linkGrid] = true
                                end
                            end
                        end
                    end
                end
            end

            local amount = 0
            for grid, _ in pairs(communityGrids) do
                local neighbours = map:FindNeighbourGrids(grid)
                for i = 1, #neighbours do
                    local neighbour = neighbours[i]
                    if neighbour:IsType(grid2) then
                        if not self:IsGridExecuted(neighbour) then
                            amount = amount + 1
                            self:SetGridExecuted(neighbour)
                        end
                    end
                end
            end
            score = amount * self:GetRewardScore()
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local grid2 = self:GetGridNameByType(self._Params[2])
        local score = self:GetRewardScore()
        return string.format(text, grid1, grid2, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(2, ruleTable)
    end,
}

--每存在一条被地块填满的【行/列】，可获得【%s】分
dictionary[5001] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        local amount = 0
        if self._Params[1] == XTempleEnumConst.LINE.ROW then
            for y = 1, map:GetRowAmount() do
                if not self:IsLineExecuted(0, y) then
                    -- 行
                    amount = 0
                    for x = 1, map:GetColumnAmount() do
                        local grid2Check = map:GetGrid(x, y)
                        if grid2Check:IsEmpty() then
                            break
                        end
                        amount = amount + 1
                    end
                    if amount == map:GetColumnAmount() then
                        score = score + self:GetRewardScore()
                        self:SetLineExecuted(0, y)
                    end
                end
            end
        else
            for x = 1, map:GetColumnAmount() do
                if not self:IsLineExecuted(1, x) then
                    -- 列
                    amount = 0
                    for y = 1, map:GetRowAmount() do
                        local grid2Check = map:GetGrid(x, y)
                        if grid2Check:IsEmpty() then
                            break
                        end
                        amount = amount + 1
                    end
                    if amount == map:GetRowAmount() then
                        score = score + self:GetRewardScore()
                        self:SetLineExecuted(1, x)
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local score = self:GetRewardScore()
        return string.format(text, self:GetLineStr(self._Params[1]), score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return { self:GetEditorOptionLine(self._Params[1]) }
    end
}

--每存在一条空白的的【行/列】，可获得【%s】分
dictionary[5002] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        if self._Params[1] == XTempleEnumConst.LINE.ROW then
            for y = 1, map:GetRowAmount() do
                if not self:IsLineExecuted(0, y) then
                    -- 行
                    local isEmpty = true
                    for x = 1, map:GetColumnAmount() do
                        local grid2Check = map:GetGrid(x, y)
                        if not grid2Check:IsEmpty() then
                            isEmpty = false
                            break
                        end
                    end
                    if isEmpty then
                        score = score + self:GetRewardScore()
                        self:SetLineExecuted(0, y)
                    end
                end
            end
        else
            for x = 1, map:GetColumnAmount() do
                if not self:IsLineExecuted(1, x) then
                    -- 列
                    local isEmpty = true
                    for y = 1, map:GetRowAmount() do
                        local grid2Check = map:GetGrid(x, y)
                        if not grid2Check:IsEmpty() then
                            isEmpty = false
                            break
                        end
                    end
                    if isEmpty then
                        score = score + self:GetRewardScore()
                        self:SetLineExecuted(1, x)
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local score = self:GetRewardScore()
        return string.format(text, self:GetLineStr(self._Params[1]), score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return { self:GetEditorOptionLine(self._Params[1]) }
    end,
}

--每存在一条被【%s】地块填满的【行/列】，可获得【%s】分
dictionary[5003] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        local amount = 0
        if self._Params[2] == XTempleEnumConst.LINE.ROW then
            for y = 1, map:GetRowAmount() do
                if not self:IsLineExecuted(0, y) then
                    -- 行
                    amount = 0
                    for x = 1, map:GetColumnAmount() do
                        local grid2Check = map:GetGrid(x, y)
                        if not grid2Check:IsType(self:GetParamsGridType(1)) then
                            break
                        end
                        amount = amount + 1
                    end
                    if amount == map:GetColumnAmount() then
                        score = score + self:GetRewardScore()
                        self:SetLineExecuted(0, y)
                    end
                end
            end
        else
            for x = 1, map:GetColumnAmount() do
                if not self:IsLineExecuted(1, x) then
                    -- 列
                    amount = 0
                    for y = 1, map:GetRowAmount() do
                        local grid2Check = map:GetGrid(x, y)
                        if not grid2Check:IsType(self:GetParamsGridType(1)) then
                            break
                        end
                        amount = amount + 1
                    end
                    if amount == map:GetRowAmount() then
                        score = score + self:GetRewardScore()
                        self:SetLineExecuted(1, x)
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local score = self:GetRewardScore()
        return string.format(text, grid1, self:GetLineStr(self._Params[2]), score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return { self:GetEditorOption4Grid(self._Params[1]), self:GetEditorOptionLine(self._Params[2]) }
    end,
}

--每存在一条包含【%s】地块的【行/列】，可获得【%s】分
dictionary[5004] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        local isInclude = false
        if self._Params[2] == XTempleEnumConst.LINE.ROW then
            for y = 1, map:GetRowAmount() do
                if not self:IsLineExecuted(0, y) then
                    -- 行
                    isInclude = false
                    for x = 1, map:GetColumnAmount() do
                        local grid2Check = map:GetGrid(x, y)
                        if grid2Check:IsType(self:GetParamsGridType(1)) then
                            isInclude = true
                        end
                    end
                    if isInclude then
                        score = score + self:GetRewardScore()
                        self:SetLineExecuted(0, y)
                    end
                end
            end
        else
            for x = 1, map:GetColumnAmount() do
                if not self:IsLineExecuted(1, x) then
                    -- 列
                    isInclude = false
                    for y = 1, map:GetRowAmount() do
                        local grid2Check = map:GetGrid(x, y)
                        if grid2Check:IsType(self:GetParamsGridType(1)) then
                            isInclude = true
                        end
                    end
                    if isInclude then
                        score = score + self:GetRewardScore()
                        self:SetLineExecuted(1, x)
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local score = self:GetRewardScore()
        return string.format(text, grid1, self:GetLineStr(self._Params[2]), score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return { self:GetEditorOption4Grid(self._Params[1]), self:GetEditorOptionLine(self._Params[2]) }
    end,
}

--【%s】地块所在的【行/列】被任意地块填满，可获得【%s】分
dictionary[5005] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        local amount = 0
        local isInclude = false
        if self._Params[2] == XTempleEnumConst.LINE.ROW then
            for y = 1, map:GetRowAmount() do
                if not self:IsLineExecuted(0, y) then
                    -- 行
                    amount = 0
                    isInclude = false
                    for x = 1, map:GetColumnAmount() do
                        local grid2Check = map:GetGrid(x, y)
                        if grid2Check:IsType(self:GetParamsGridType(1)) then
                            isInclude = true
                        end
                        if not grid2Check:IsEmpty() then
                            amount = amount + 1
                        end
                    end
                    if amount == map:GetColumnAmount() and isInclude then
                        score = score + self:GetRewardScore()
                        self:SetLineExecuted(0, y)
                    end
                end
            end
        else
            for x = 1, map:GetColumnAmount() do
                if not self:IsLineExecuted(1, x) then
                    -- 列
                    amount = 0
                    isInclude = false
                    for y = 1, map:GetRowAmount() do
                        local grid2Check = map:GetGrid(x, y)
                        if grid2Check:IsType(self:GetParamsGridType(1)) then
                            isInclude = true
                        end
                        if not grid2Check:IsEmpty() then
                            amount = amount + 1
                        end
                    end
                    if amount == map:GetRowAmount() and isInclude then
                        score = score + self:GetRewardScore()
                        self:SetLineExecuted(1, x)
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local score = self:GetRewardScore()
        return string.format(text, grid1, self:GetLineStr(self._Params[2]), score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return { self:GetEditorOption4Grid(self._Params[1]), self:GetEditorOptionLine(self._Params[2]) }
    end,
}

--每存在一个未被包围的【%s】地块，扣除【%s】分。注意这里是负分，要减分的
dictionary[6001] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                ---@type XTempleGrid
                local grid = map:GetGrid(x, y)
                if grid:IsType(self:GetParamsGridType(1)) then
                    if not self:IsGridExecuted(grid) then
                        local neighbourGrids = map:FindNeighbourGrids(grid)
                        if not self:IsSurroundBySomeGrids(neighbourGrids) then
                            -- 无论策划怎么填，都减分
                            score = score - math.abs(self:GetRewardScore())
                            self:SetGridExecuted(grid)
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local score = self:GetRewardScore()
        return string.format(text, grid1, math.abs(score))
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(1, ruleTable)
    end,
}

--【福字地块】旋转180度
dictionary[7001] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param grid XTempleGrid
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        local blockId = self._Params[1]
        ---@type XTempleBlock
        local block = map:GetBlockById(blockId)
        if block then
            local blockX = block:GetColumnAmount()
            local blockY = block:GetRowAmount()
            for y = 1, map:GetRowAmount() do
                for x = 1, map:GetColumnAmount() do
                    local grid = map:GetGrid(x, y)
                    if not self:IsGridExecuted(grid) then
                        if block:CheckShape(map, x, y, x + blockX - 1, y + blockY - 1) then
                            local grids = block:CollectShapeGrids(map, x, y, x + blockX - 1, y + blockY - 1)
                            score = score + self:GetRewardScore()
                            self:SetGridsExecuted(grids)
                        end
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        return text
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return {  }
    end,
}

-- 场上每有1个【%s】地块，可获得【%s】分
dictionary[8001] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        local score = 0
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                local grid = map:GetGrid(x, y)

                local isOk = false
                if not self:IsGridExecuted(grid) then
                    if grid:IsType(self:GetParamsGridType(1)) then
                        score = score + self:GetRewardScore()
                        self:SetGridExecuted(grid)
                        isOk = true
                    end
                end
            end
        end
        return score
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local score = self:GetRewardScore()
        return string.format(text, grid1, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(1, ruleTable)
    end,
}

-- 若场上数量最多的地块是【%s】地块，每个【%s】地块可获得【%s】分
dictionary[8002] = {
    ---@alias XTempleRuleExecute function
    ---@param self XTempleRule
    ---@param map XTempleMap
    ---@return boolean, number, XTempleGrid[]
    Execute = function(self, map)
        if self:IsSelfExecuted() then
            return 0
        end
        local typeAmount = {}
        for y = 1, map:GetRowAmount() do
            for x = 1, map:GetColumnAmount() do
                local grid2Check = map:GetGrid(x, y)
                if not grid2Check:IsEmpty() then
                    local type = grid2Check:GetType()
                    typeAmount[type] = typeAmount[type] or 0
                    typeAmount[type] = typeAmount[type] + 1
                end
            end
        end
        local max = 0
        for i, v in pairs(typeAmount) do
            if v > max then
                max = v
            end
        end
        if not self._TypeAmountDict then
            self._TypeAmountDict = typeAmount
        end
        local type = self._Params[1]
        if typeAmount[type] == max then
            if self._TypeAmountDict[type] ~= max then
                self:SetSelfExecuted()
                return self:GetRewardScore() * max
            end
        end
        return 0
    end,
    ---@param self XTempleRule
    GetText = function(self)
        local text = self:GetRuleText()
        local grid1 = self:GetGridNameByType(self._Params[1])
        local score = self:GetRewardScore()
        return string.format(text, grid1, grid1, score)
    end,
    ---@param self XTempleRule
    EditorGetOption = function(self, ruleTable)
        return self:GetEditorOptionArray4Grid(1, ruleTable)
    end,
}

return dictionary
