
local UIRepeatChallengeNewChapterNumIconPath = {
    [1] = CS.XGame.ClientConfig:GetString("UIRepeatChallengeNewChapterNumIconPath1"),
    [2] = CS.XGame.ClientConfig:GetString("UIRepeatChallengeNewChapterNumIconPath2"),
    [3] = CS.XGame.ClientConfig:GetString("UIRepeatChallengeNewChapterNumIconPath3"),
    [4] = CS.XGame.ClientConfig:GetString("UIRepeatChallengeNewChapterNumIconPath4"),
    [5] = CS.XGame.ClientConfig:GetString("UIRepeatChallengeNewChapterNumIconPath5"),
}

local XUiFubenRepeatChallengeNewChapter = XLuaUiManager.Register(XLuaUi, "UiFubenRepeatChallengeNewChapter")

function XUiFubenRepeatChallengeNewChapter:OnAwake()
    self:AutoAddListener()
end

function XUiFubenRepeatChallengeNewChapter:OnStart(oldIndex, newIndex)
    self:Refresh(oldIndex, newIndex)
end

function XUiFubenRepeatChallengeNewChapter:Refresh(oldIndex, newIndex)

    local oldPath =  UIRepeatChallengeNewChapterNumIconPath[oldIndex]
    local newPath =  UIRepeatChallengeNewChapterNumIconPath[newIndex]

    if oldPath then
        self:SetUiSprite(self.ImgOldChpaterOrder,oldPath)
    end

    if newPath then
        self:SetUiSprite(self.ImgOldChpaterOrder,newPath)
    end

    local level = XDataCenter.FubenRepeatChallengeManager.GetLevel()
    local exp = XDataCenter.FubenRepeatChallengeManager.GetExp()
    local levelConfig = XFubenRepeatChallengeConfigs.GetLevelConfig(level)
    local curLevelMaxExp = levelConfig.UpExp
    self.TxtLevel.text = level
    self.ImgExp.fillAmount = exp / curLevelMaxExp
end

function XUiFubenRepeatChallengeNewChapter:AutoAddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end

function XUiFubenRepeatChallengeNewChapter:OnBtnCloseClick()
    self:Close()
end