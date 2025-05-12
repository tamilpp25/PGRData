--肉鸽玩法招募主界面
local XUiTheatreRecruit = XLuaUiManager.Register(XLuaUi, "UiTheatreRecruit")
local XUiTheatreRecruitMemberPanel = require("XUi/XUiTheatre/Recruit/XUiTheatreRecruitMemberPanel")
local XUiTheatreRecruitRolePanel = require("XUi/XUiTheatre/Recruit/XUiTheatreRecruitRolePanel")
local XUiPanelRoleModel = require("XUi/XUiCharacter/XUiPanelRoleModel")

function XUiTheatreRecruit:OnAwake()
    XUiHelper.NewPanelActivityAssetSafe(XDataCenter.TheatreManager.GetAdventureAssetItemIds(), self.PanelSpecialTool, self)
    self:AddListener()
end

function XUiTheatreRecruit:OnStart(chapterId, isPlayMovie)
    -- 默认不播放
    if isPlayMovie == nil then isPlayMovie = false end
    self.IsPlayMovie = isPlayMovie
    self.ChapterId = chapterId
    self.AdventureManager = XDataCenter.TheatreManager.GetCurrentAdventureManager()
    self.AdventureChapter = self.AdventureManager:GetCurrentChapter()
    self:SetCharacterList()
    self:UpdateSceneUrl()
    self:Set3DCharacter()
end

function XUiTheatreRecruit:OnEnable()
    XDataCenter.TheatreManager.SetSceneActive(true)
    self:Refresh()
    XEventManager.AddEventListener(XEventId.EVENT_THEATRE_RECRUIT_COMPLETE, self.UpdateRecruitNumber, self)
    if table.nums(self.AdventureChapter:GetRecruitRoleDic()) <= 0 then
        -- 默认刷新一次
        self.AdventureChapter:RequestRefreshRoles(function()
            self.Character3DPanel:UpdateData(true)
            self:UpdateRefreshCount()
        end, false)
    end
    local beginStoryId = self.AdventureChapter:GetBeginStoryId()
    if beginStoryId and self.IsPlayMovie then
        XDataCenter.MovieManager.PlayMovie(beginStoryId, function()
            self.IsPlayMovie = false
            XDataCenter.TheatreManager.SetSceneActive(true)
        end)
    end
end

function XUiTheatreRecruit:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_THEATRE_RECRUIT_COMPLETE, self.UpdateRecruitNumber, self)
end

function XUiTheatreRecruit:OnDestroy()
    self.CharacterList:RemoveEventListeners()
    self.Character3DPanel:Destroy()
end

function XUiTheatreRecruit:Refresh()
    self:UpdateRecruitNumber()
    self:UpdateRefreshCount()
    self:UpdateBg()
    --当没有剩余招募人数时，确定按钮会有提示点击的闪烁特效
    --self.AdventureChapter:GetRecruitCount() > 0
end

function XUiTheatreRecruit:UpdateSceneUrl()
    XDataCenter.TheatreManager.UpdateSceneUrl(self)
    XScheduleManager.ScheduleOnce(function()
        XDataCenter.TheatreManager.ShowRoleModelCamera(self, "FarCameraRecruit", "NearCameraRecruit")
    end, 1)
end

--刷新次数
function XUiTheatreRecruit:UpdateRefreshCount()
    local lastRefreshCount = self.AdventureChapter:GetRefreshRoleCount()
    local maxRefreshCount = self.AdventureChapter:GetRefreshRoleMaxCount()
    self.TxtRefreshCount.text = lastRefreshCount .. "/" .. maxRefreshCount
end

--剩余招募次数
function XUiTheatreRecruit:UpdateRecruitNumber()
    self.TxtRecruitCount.text = self.AdventureChapter:GetRecruitCount()
end

function XUiTheatreRecruit:AddListener()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnRefresh, self.OnBtnRefreshClick)
    self:BindHelpBtn(self.BtnHelp, "TheTheatreFightGuide")
    self:RegisterClickEvent(self.BtnFight, self.OnBtnFightClick)
end

function XUiTheatreRecruit:OnBtnBackClick()
    self:OpenLeaveTips(handler(self, self.Close))
end

function XUiTheatreRecruit:OnBtnMainUiClick()
    self:OpenLeaveTips(XLuaUiManager.RunMain)
end

function XUiTheatreRecruit:OpenLeaveTips(sureCallback)
    local desc = CsXTextManagerGetText("TheatreLeaveTipsDesc")
    XUiManager.DialogTip(nil, desc, nil, nil, sureCallback)
end

function XUiTheatreRecruit:OnBtnRefreshClick()
    self.AdventureChapter:RequestRefreshRoles(function()
        self.Character3DPanel:UpdateData(true)
        self:UpdateRefreshCount()
    end)
end

--开始冒险
function XUiTheatreRecruit:OnBtnFightClick()
    if not self.AdventureChapter:GetIsCanEnterGame() then
        XUiManager.TipText("TheatreRecruitCountHasLeft")
        return
    end
    --局内-选择格子前进
    self:Remove()
    XLuaUiManager.Open("UiTheatrePlayMain")
end

function XUiTheatreRecruit:SetCharacterList()
    self.CharacterList = XUiTheatreRecruitMemberPanel.New(self.SViewCharacterList, self)
    self.CharacterList:UpdateData()
end

function XUiTheatreRecruit:Set3DCharacter()
    local uiModelGo = XDataCenter.TheatreManager.GetUiModelGo()
    if XTool.UObjIsNil(uiModelGo) then
        return
    end

    local uiModelRoot = uiModelGo.transform
    local models = {
        [1] = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelModelCase1"), self.Name, nil, true, nil, true, true),
        [2] = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelModelCase2"), self.Name, nil, true, nil, true, true),
        [3] = XUiPanelRoleModel.New(uiModelRoot:FindTransform("PanelModelCase3"), self.Name, nil, true, nil, true, true),
    }
    self.Character3DPanel = XUiTheatreRecruitRolePanel.New(self.PanelChar, self, models)
    self.Character3DPanel:UpdateData(true)
end

function XUiTheatreRecruit:UpdateBg()
    local chapter = self.AdventureManager:GetCurrentChapter()
    local chapterId = chapter:GetCurrentChapterId()
    if self.RImgBgA then
        local bgA = XTheatreConfigs.GetChapterBgA(chapterId)
        self.RImgBgA:SetRawImage(bgA)
    end
    if self.RImgBgB then
        local bgB = XTheatreConfigs.GetChapterBgB(chapterId)
        self.RImgBgB:SetRawImage(bgB)
    end
end