local XTemple2Enum = require("XModule/XTemple2/XTemple2Enum")

local STATE = {
    NONE = 0,
    WALK_BEGIN = 1,
    WALK = 2,
    WALK_END = 3,
    START_ANIMATION = 4,
    WAIT_ANIMATION = 5,
    FINISH = 6,
}

local BUBBLE_TYPE = XTemple2Enum.BUBBLE

---@class XTemple2Animation
local XTemple2Animation = XClass(nil, "XTemple2Animation")

function XTemple2Animation:Ctor()
    self._State = STATE.NONE
    self._Data = false
    self._Time = 0
    self._DurationOfOneGrid = 0.5
    self._Path = false
    self._GridSize = XTemple2Enum.GRID_SIZE
    self._TempPosition = Vector2()
    ---@type XTemple2GameControlAnimationData[]
    self._AnimationDataList = {  }

    ---@type XTemple2GameControlAnimationScore[][]
    self._ScoreDataList = {}

    self._CurrentAnimationData = false
    self._WaitTime = 0
end

function XTemple2Animation:StartWalk(path, animationDataList)
    self._Path = path
    if animationDataList then
        self._AnimationDataList = animationDataList.Path
        self._ScoreDataList = animationDataList.JumpScore
    else
        self._AnimationDataList = {}
    end
    self._State = STATE.WALK_BEGIN
end

---@param ui XUiTemple2CheckBoard
function XTemple2Animation:Update(ui, game)
    if self._State == STATE.NONE then
        self._State = STATE.WALK_BEGIN
        return
    end

    if self._State == STATE.WALK_BEGIN then
        self._State = STATE.WALK
        self._Time = 0
        ---@type XUiTemple2CheckBoardRole
        local character = ui:GetCharacter()
        character:Open()
        return
    end

    if self._State == STATE.WALK then
        if not self._Path then
            self._State = STATE.WALK_END
            return
        end

        self._Time = self._Time + CS.UnityEngine.Time.deltaTime
        local posIndex = math.floor(self._Time / self._DurationOfOneGrid) + 1

        local animationData = self:QueueAnimationData(posIndex)
        if animationData then
            self._CurrentAnimationData = animationData
            self._State = STATE.START_ANIMATION
            return
        end

        if posIndex == 1 then
            self:PlayScoreBubble(ui, posIndex)
            self:PlayScoreBubble(ui, posIndex + 1)
            self:PlayScoreBubble(ui, posIndex + 2)
        else
            self:PlayScoreBubble(ui, posIndex + 2)
        end

        local pos1 = self._Path[posIndex]
        if not pos1 then
            self._State = STATE.WALK_END
            return
        end

        local pos2 = self._Path[posIndex + 1]
        if not pos2 then
            self._State = STATE.WALK_END
            return
        end

        local time = self._Time - (posIndex - 1) * self._DurationOfOneGrid
        local passed = time / self._DurationOfOneGrid
        local remain = 1 - passed
        local x = pos1.x * remain + pos2.x * passed
        local y = pos1.y * remain + pos2.y * passed
        self._TempPosition.x = (x - 1) * self._GridSize
        self._TempPosition.y = (y - 1) * self._GridSize

        ---@type XUiTemple2CheckBoardRole
        local character = ui:GetCharacter()
        if character then
            character.Transform.anchoredPosition = self._TempPosition
        end
        if remain == 0 then
            self._State = STATE.WALK_END
        end
        return
    end

    if self._State == STATE.START_ANIMATION then
        self._State = STATE.WAIT_ANIMATION
        local animationData = self._CurrentAnimationData
        if animationData then
            if animationData.Type == BUBBLE_TYPE.STORY then
                --无限等待
                self._WaitTime = 0xffffffff
                if XDataCenter.MovieManager.CheckMovieExist(animationData.StoryId) then
                    XMVCA.XTemple2:PlayMovie(animationData.StoryId, function()
                        self._State = STATE.WALK
                    end)
                else
                    self._State = STATE.WALK
                    XLog.Error("剧情不存在:", animationData.StoryId)
                end
                if self._State == STATE.WALK then
                    XLog.Error("跳过剧情:", animationData.StoryId)
                    XUiManager.TipText("跳过剧情")
                end

            elseif animationData.Type == BUBBLE_TYPE.EMOJI then
                ---@type XUiTemple2CheckBoardRole
                local character = ui:GetCharacter()
                if character then
                    character:SetEmoj(animationData.Icon)
                end
                -- 等待气泡时间
                self._WaitTime = 3
            end
        end
        return
    end

    if self._State == STATE.WAIT_ANIMATION then
        self._WaitTime = self._WaitTime - CS.UnityEngine.Time.deltaTime
        if self._WaitTime <= 0 then
            self._WaitTime = 0
            self._State = STATE.WALK

            local animationData = self._CurrentAnimationData
            if animationData then
                if animationData.Type == BUBBLE_TYPE.STORY then
                    XDataCenter.MovieManager.StopMovie()
                elseif animationData.Type == BUBBLE_TYPE.EMOJI then
                    ---@type XUiTemple2CheckBoardRole
                    local character = ui:GetCharacter()
                    if character then
                        character:SetEmoj(false)
                    end
                end
            end
            self._CurrentAnimationData = false
        end
        -- 等待剧情播放结束
        return
    end

    if self._State == STATE.WALK_END then
        self._State = STATE.FINISH
        return
    end
end

function XTemple2Animation:IsPlaying()
    return self._State ~= STATE.NONE
end

function XTemple2Animation:IsFinish()
    return self._State == STATE.FINISH
end

function XTemple2Animation:QueueAnimationData(index)
    for i = 1, #self._AnimationDataList do
        local animationData = self._AnimationDataList[i]
        if animationData.Index > index then
            break
        end
        if animationData.Index == index then
            table.remove(self._AnimationDataList, i)
            return animationData
        end
    end
    return nil
end

function XTemple2Animation:QueueAnimationScoreData(index)
    local list = self._ScoreDataList[index]
    return list
end

---@param ui XUiTemple2CheckBoard
function XTemple2Animation:PlayScoreBubble(ui, posIndex)
    ---@type XTemple2GameControlAnimationScore
    local jumpScoreDataList = self:QueueAnimationScoreData(posIndex)
    if jumpScoreDataList then
        for i = 1, #jumpScoreDataList do
            local jumpScoreData = jumpScoreDataList[i]
            local grid = ui:GetGrid(jumpScoreData.x, jumpScoreData.y)
            if grid then
                grid:PlayScoreAnimation(jumpScoreData.Score)
            end
        end
    end
end

return XTemple2Animation