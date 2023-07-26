-- 白色情人节约会活动邀约故事UI控件
local XUiWhiteValentineStory = XLuaUiManager.Register(XLuaUi, "UiWhitedayObtain")

function XUiWhiteValentineStory:OnAwake()
    XTool.InitUiObject(self)
    self:InitButtons()
end

function XUiWhiteValentineStory:OnStart(chara, storyType)
    self.Chara = chara
    self.StoryType = storyType
    self:InitStory()
    self:InitChara()
end

function XUiWhiteValentineStory:InitButtons()
    self:RegisterClickEvent(self.BtnSure, function() self:OnBtnClose() end)
end

function XUiWhiteValentineStory:OnBtnClose()
    self:Close()
end

function XUiWhiteValentineStory:InitStory()
    local storyCfg = self.Chara:GetStoryByStoryType(self.StoryType)
    if storyCfg then
        self.TxtTitle.text = storyCfg.Title
        self.TxtStory.text = storyCfg.StoryText
    end
end

function XUiWhiteValentineStory:InitChara()
    local XCharaGrid = require("XUi/XUiMiniGame/WhiteValentine2021/XUiWhiteValenInviteCharaGrid")
    XCharaGrid.New(self.GridChara, self.Chara)
end

