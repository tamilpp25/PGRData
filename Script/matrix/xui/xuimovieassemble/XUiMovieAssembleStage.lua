local tableInsert = table.insert
local CsXTextManagerGetText = CS.XTextManager.GetText
local XUiMovieAssembleStage = XClass(nil, "XUiMovieAssembleStage")

function XUiMovieAssembleStage:Ctor(rootUi, ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    self:Init()
end

function XUiMovieAssembleStage:Init()
    self.GameObject:SetActiveEx(true)
    self:AutoRegisterListener()
end

function XUiMovieAssembleStage:OnCreat(movieId)
    self.MovieId = movieId
    if self.RImgStageNorBg then
        local unlockImgUrl = XMovieAssembleConfig.GetMovieUnlockBgUrlById(self.MovieId)
        if unlockImgUrl and unlockImgUrl ~= "" then
            self.RImgStageNorBg:SetRawImage(unlockImgUrl)
        end
    end

    if self.RImgStageLockBg then
        local lockImgUrl = XMovieAssembleConfig.GetMovieLockedBgUrlById(self.MovieId)
        if lockImgUrl and lockImgUrl ~= "" then
            self.RImgStageLockBg:SetRawImage(lockImgUrl)
        end
    end

    local isUnlock = false
    local conditionId = XMovieAssembleConfig.GetMovieConditionIdById(self.MovieId)
    if conditionId and conditionId ~= 0 then
        isUnlock = XConditionManager.CheckCondition(conditionId)
    else
        isUnlock = true
    end
    self:SetUnLock(isUnlock)
    self:InitRedPoint()
end

function XUiMovieAssembleStage:SetUnLock(bool)
    if self.StageMaskUnlocking then self.StageMaskUnlocking.gameObject:SetActiveEx(bool) end
    if self.StageMaskLocking then self.StageMaskLocking.gameObject:SetActiveEx(not bool) end
end

function XUiMovieAssembleStage:AutoRegisterListener()
    if self.BtnPressArea then
        self.BtnPressArea.CallBack = function ()
            self:OnClick()
        end
    end
end

function XUiMovieAssembleStage:OnClick()
    if self.MovieId then
        local conditionId = XMovieAssembleConfig.GetMovieConditionIdById(self.MovieId)
        if conditionId and conditionId ~= 0 then
            local isUnlock, desc = XConditionManager.CheckCondition(conditionId)
            if isUnlock then
                self.RootUi:PlayMovie(self.MovieId)
            else
                XUiManager.TipMsg(CsXTextManagerGetText("MovieAssembleConditionDesc", desc))
            end
        else
            self.RootUi:PlayMovie(self.MovieId)
        end
    end
end

function XUiMovieAssembleStage:InitRedPoint()
    if self.RedId then
        XRedPointManager.RemoveRedPointEvent(self.RedId)
        self.RedId = nil
    end
    self.RedId = XRedPointManager.AddRedPointEvent(self.BtnPressArea.ReddotObj, nil, nil, {XRedPointConditions.Types.CONDITION_MOVIE_ASSEMBLE_MOVIE_RED}, self.MovieId, true)
end

return XUiMovieAssembleStage