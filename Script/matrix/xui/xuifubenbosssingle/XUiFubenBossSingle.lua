local XUiPanelAsset = require("XUi/XUiCommon/XUiPanelAsset")
---@class XUiFubenBossSingle : XLuaUi
---@field _Control XFubenBossSingleControl
local XUiFubenBossSingle = XLuaUiManager.Register(XLuaUi, "UiFubenBossSingle")
local XUiPanelBossStage = require("XUi/XUiFubenBossSingle/XUiPanelBossStage")
local XUiPanelBossRankInfo = require("XUi/XUiFubenBossSingle/XUiPanelBossRankInfo")
local XUiPanelBossEnter = require("XUi/XUiFubenBossSingle/XUiPanelBossEnter")
local XUiPanelRankReward = require("XUi/XUiFubenBossSingle/XUiPanelRankReward")

function XUiFubenBossSingle:OnAwake()
    self:_HideEffect()
    self:_RegisterButtonListeners()
end

function XUiFubenBossSingle:OnStart()
    local bossSingleData = self._Control:GetBossSingleData()
    local bossList = bossSingleData:GetBossSingleBossList()
    
    self._IsShowMainPanel = true
    ---@type XUiPanelBossStage
    self._BossList = XUiPanelBossStage.New(self.PanelBossStgae, self, bossList)
    ---@type XUiPanelBossEnter
    self._BossEnter = XUiPanelBossEnter.New(self.PanelBossEnter, self)
    ---@type XUiPanelBossRankInfo
    self._BossRankInfo = XUiPanelBossRankInfo.New(self.PanelBossRankInfo, self)
    ---@type XUiPanelRankReward
    self._RankReward = XUiPanelRankReward.New(self.PanelRankReward, self)
    self._RankReward:Close()

    XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.ItemManager.ItemId.FreeGem, XDataCenter.ItemManager.ItemId.ActionPoint, XDataCenter.ItemManager.ItemId.Coin)
end

function XUiFubenBossSingle:OnEnable()
    self:_Refresh()
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_REFRESH_STAGE_DATA, self.OnSyncBossData, self)
    XEventManager.AddEventListener(XEventId.EVENT_BOSS_SINGLE_GET_REWARD, self.OnRewardGet, self)
    XEventManager.AddEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET, self.OnActivityEnd, self)
end

function XUiFubenBossSingle:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_REFRESH_STAGE_DATA, self.OnSyncBossData, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BOSS_SINGLE_GET_REWARD, self.OnRewardGet, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_FUBEN_SINGLE_BOSS_RESET, self.OnActivityEnd, self)
end

function XUiFubenBossSingle:_RegisterButtonListeners()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:BindHelpBtn(self.BtnHelp, "BossSingle")
end

function XUiFubenBossSingle:_HideEffect()
    local root = self.UiModelGo.transform
    local imgEffect = root:FindTransform("ImgEffectHuanren")
    local imgEffectHide = root:FindTransform("ImgEffectHuanren1")

    if imgEffect then
        imgEffect.gameObject:SetActiveEx(false)
    end
    if imgEffectHide then
        imgEffectHide.gameObject:SetActiveEx(false)
    end
end

function XUiFubenBossSingle:_Refresh()
    self:OnSyncBossData()
end

function XUiFubenBossSingle:_OpenMainPanel(isRefresh)
    self._IsShowMainPanel = true
    self._BossList:Open()
    self._BossEnter:Open()
    self._BossEnter:Refresh(isRefresh)
    self._BossRankInfo:Close()
end

function XUiFubenBossSingle:_OpenRankPanel()
    self._IsShowMainPanel = false
    self._BossList:Close()
    self._BossEnter:Close()
    self._BossRankInfo:Open()
end

function XUiFubenBossSingle:OnSyncBossData()
    self:_OpenMainPanel(true)
end

function XUiFubenBossSingle:OnRewardGet()
    self._BossEnter:CheckRedPoint()
end

function XUiFubenBossSingle:OnActivityEnd()
    self._Control:OnActivityEnd()
end

function XUiFubenBossSingle:OnBtnBackClick()
    if not self._IsShowMainPanel then
        self:_OpenMainPanel()
    else
        self:Close()
    end
end

function XUiFubenBossSingle:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFubenBossSingle:GetBossSingleData()
    return self._Control:GetBossSingleData()
end

function XUiFubenBossSingle:ShowBossRank()
    self:_OpenRankPanel()
end

function XUiFubenBossSingle:ShowBossGroupInfo(groupId)
    self._BossEnter:ShowBossGroupInfo(groupId)
end

function XUiFubenBossSingle:ShowRankRewardPanel(levelType, myRankData)
    self._RankReward:SetData(levelType, myRankData)
    self._RankReward:Open()
end

function XUiFubenBossSingle:ShowBossDetail(bossId)
    XLuaUiManager.Open("UiFubenBossSingleDetail", bossId)
end

return XUiFubenBossSingle