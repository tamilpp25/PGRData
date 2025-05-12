-- XPanelPsionicVisionOff 肉鸽玩法2.1 灵视栏
-- ================================================================================
local XPanelPsionicVisionOff = XClass(nil, "XPanelPsionicVisionOff")

function XPanelPsionicVisionOff:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
	self.RootUi = rootUi
    self.IconBg = self.IconBg.gameObject:GetComponent("RawImage")
    XUiHelper.RegisterClickEvent(self, self.ImgProgress, self.OnOpenClick)
    XUiHelper.RegisterClickEvent(self, self.ImgJD, self.OnOpenClick)
    XUiHelper.RegisterClickEvent(self, self.ImgJiantou, self.OnOpenClick)
end

function XPanelPsionicVisionOff:RefreshVision()
    local visionValue = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():GetVisionValue()
    local visionId = XBiancaTheatreConfigs.GetVisionIdByValue(visionValue)
    if self.IconBg then self.IconBg:SetRawImage(XBiancaTheatreConfigs.GetVisionIcon(visionId)) end
    self.ImgProgress.fillAmount = visionValue / 100
    self.TxtJD.text = visionId
    self.TxtNum.text = visionValue
end

function XPanelPsionicVisionOff:OnOpenClick()
    self.RootUi:SetVisionActive(true)
end

function XPanelPsionicVisionOff:SetActive(active)
    self.GameObject:SetActiveEx(active)
    if active then
        self:RefreshVision()
    end
end


-- XPanelPsionicVisionOn 肉鸽玩法2.1 灵视面板
-- ================================================================================
local XPanelPsionicVisionOn = XClass(nil, "XPanelPsionicVisionOn")

function XPanelPsionicVisionOn:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
	self.RootUi = rootUi
    self.IconBg = self.IconBg.gameObject:GetComponent("RawImage")
    XUiHelper.RegisterClickEvent(self, self.BtnCloseDetail, self.OnCloseClick)
    XUiHelper.RegisterClickEvent(self, self.ImgProgress, self.OnCloseClick)
end

function XPanelPsionicVisionOn:RefreshVision()
    local visionValue = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():GetVisionValue()
    local visionId = XBiancaTheatreConfigs.GetVisionIdByValue(visionValue)
    if self.IconBg then self.IconBg:SetRawImage(XBiancaTheatreConfigs.GetVisionIcon(visionId)) end
    self.ImgProgress.fillAmount = visionValue / 100
    self.TxtJD.text = visionId
    self.TxtNum.text = visionValue
    self.TxtDesc.gameObject:SetActiveEx(false)
    self.TxtRecord.gameObject:SetActiveEx(false)
    self:RefreshTxtShake(visionId)
end

function XPanelPsionicVisionOn:RefreshTxtShake(visionId)
    local chapterId = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager():GetCurrentChapter():GetCurrentChapterId()
    local descGroupId = XBiancaTheatreConfigs.GetVisionDescShakeGroupId(visionId)
    local recordGroupId = XBiancaTheatreConfigs.GetVisionRecordDescShakeGroupId(visionId)
    local descTxtList = XBiancaTheatreConfigs.GetVisionShakeIdListByGroupId(descGroupId, chapterId)
    local recordTxtList = XBiancaTheatreConfigs.GetVisionShakeIdListByGroupId(recordGroupId, chapterId)
    if not XTool.IsTableEmpty(descTxtList) then
        for index, config in ipairs(descTxtList) do
            if self["TxtDesc"..index] then
                self:RefreshTextMeshEffect(self["TxtDesc"..index], config)
            end
        end
    end
    if not XTool.IsTableEmpty(descTxtList) then
        for index, config in ipairs(recordTxtList) do
            if self["TxtRecord"..index] then
                self:RefreshTextMeshEffect(self["TxtRecord"..index], config)
            end
        end
    end
end

function XPanelPsionicVisionOn:RefreshTextMeshEffect(textComponent, config)
    local textMeshEffect = textComponent.gameObject:GetComponent(typeof(CS.TextMeshEffect))
    textComponent.text = config.Txt
    textMeshEffect.startIndex = config.StartIndex
    textMeshEffect.endIndex = config.EndIndex
    textMeshEffect.textHorizontalShakeType = config.HShakeType
    textMeshEffect.shakeHorizontalStrength = config.Hstrength
    textMeshEffect.shakeHorizontalSpeed = config.HSpeed
    textMeshEffect.shakeHorizontalDensity = config.HoriDensity
    textMeshEffect.textVerticalShakeType = config.VShakeType
    textMeshEffect.shakeVerticalStrength = config.VStrength
    textMeshEffect.shakeVerticalSpeed = config.VSpeed
    textMeshEffect.shakeVerticalDensity = config.VDensity
    textComponent.gameObject:SetActiveEx(true)
end

function XPanelPsionicVisionOn:OnCloseClick()
    self.RootUi:SetVisionActive(false)
end

function XPanelPsionicVisionOn:SetActive(active)
    self.GameObject:SetActiveEx(active)
    if active then
        self:RefreshVision()
    end
end


-- XUiBiancaTheatreNode 肉鸽玩法2.1 选择节点
-- ================================================================================
local XUiRewardGrid = require("XUi/XUiBiancaTheatre/Common/XUiRewardGrid")
local XUiBiancaTheatreNode = XClass(nil, "XUiBiancaTheatreNode")
local NodeRewardMaxShowCount = 1

function XUiBiancaTheatreNode:Ctor(ui, rootUi)
    XUiHelper.InitUiClass(self, ui)
    self.Node = nil
    self.RootUi = rootUi
    XUiHelper.RegisterClickEvent(self, self.BtnSelect, self.OnBtnComfirmClicked)
    self.ItemGridList = {}
end

-- node : XANode
function XUiBiancaTheatreNode:SetData(node)
    self.Node = node
    -- 类型图标
    self.RImgIcon:SetRawImage(node:GetNodeTypeIcon())
    -- 节点小图标
    local icon = node:GetNodeTypeSmallIcon()
    if icon then
        self.Icon:SetRawImage(icon)
    end
    self.Icon.gameObject:SetActiveEx(icon and true or false)
    -- 节点显示名字
    self.TxtName.text = node:GetNodeTypeName()
    self.TxtTeamNumber.gameObject:SetActiveEx(false)
    -- 节点详情
    local simpleDesc = node:GetNodeTypeDesc()
    self.TxtDetail.gameObject:SetActiveEx(simpleDesc ~= nil)
    if simpleDesc ~= nil then
        self.TxtDetail.text = string.gsub(simpleDesc, "\\n", "\n")
    end
    -- 是否已被禁用
    self.PanelDisable.gameObject:SetActiveEx(node:GetIsDisable())
    -- 底下图标显示显示
    local childCount = self.PanelReward.childCount
    for i = 0, childCount - 1 do
        self.PanelReward:GetChild(i).gameObject:SetActiveEx(false)
    end
    local showDatas = node:GetShowDatas()
    for i = 1, #showDatas do
        local showData = showDatas[i]
        local child = nil
        if i > NodeRewardMaxShowCount then break end
        if i > childCount then
            child = XUiHelper.Instantiate(self.GridReward.gameObject, self.PanelReward)
        else
            child = self.PanelReward:GetChild(i - 1)
        end
        child.gameObject:SetActiveEx(true)
        local itemGrid = self.ItemGridList[i]
        if not itemGrid then
            itemGrid = XUiRewardGrid.New(self.GridReward)
            self.ItemGridList[i] = itemGrid
        end
        itemGrid:Refresh(showData.rewardNode)
    end
    -- 灵视特效
    self:UpdateNodeEffect(node)
    return self
end

-- 更新节点特效
function XUiBiancaTheatreNode:UpdateNodeEffect(node)
    local effectUrl = node:GetNodeTypeEffectUrl()
    if not string.IsNilOrEmpty(effectUrl) then
        self.Effect.gameObject:LoadUiEffect(effectUrl)
        self.Effect.gameObject:SetActiveEx(true)
    else
        self.Effect.gameObject:SetActiveEx(false)
    end
end

function XUiBiancaTheatreNode:OnRewardClicked(data)
    if data.rewardType == XBiancaTheatreConfigs.AdventureRewardType.RewardId then
        XUiManager.OpenUiTipRewardByRewardId(data.rewardId)
        return
    end
    local configNname
    if data.rewardType == XBiancaTheatreConfigs.AdventureRewardType.SelectSkill then
        configNname = "SelectSkillDetail"
    elseif data.rewardType == XBiancaTheatreConfigs.AdventureRewardType.LevelUp then
        configNname = "LevelUpDetail"
    end
    local icon = XBiancaTheatreConfigs.GetClientConfig(configNname, 1)
    local content = XBiancaTheatreConfigs.GetClientConfig(configNname, 3)
    if data.rewardType == XBiancaTheatreConfigs.AdventureRewardType.SelectSkill then
        icon = string.format(icon, XBiancaTheatreConfigs.GetClientConfig("SelectSkillDetailIcon", data.powerId))
        content = string.format(content, XBiancaTheatreConfigs.GetClientConfig("SelectSkillDetailDesc", data.powerId))
    end
end

function XUiBiancaTheatreNode:OnBtnComfirmClicked()
    self.Node:Trigger()
end

function XUiBiancaTheatreNode:PlaySelectAnim()
    self.AnimSelect:Play()
end

function XUiBiancaTheatreNode:StopSelectAnim()
    self.AnimSelect:Stop()
    self.AnimSelect:Evaluate()
end


-- XUiBiancaTheatrePlayMain 肉鸽玩法2.1 内循环玩法主界面
-- ================================================================================
local XUiBiancaTheatrePanelDown = require("XUi/XUiBiancaTheatre/Common/XUiBiancaTheatrePanelDown")
local XUiBiancaTheatrePanelFetters = require("XUi/XUiBiancaTheatre/Common/XUiBiancaTheatrePanelFetters")
local XUiPanelItemChange = require("XUi/XUiBiancaTheatre/Common/XUiPanelItemChange")
local XUiBiancaTheatrePlayMain = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatrePlayMain")

function XUiBiancaTheatrePlayMain:OnAwake()
    self.TheatreManager = XDataCenter.BiancaTheatreManager
    self.AdventureManager = self.TheatreManager.GetCurrentAdventureManager()
    self.CurrentChapter = self.AdventureManager:GetCurrentChapter()
    -- 注册资源面板
    XUiHelper.NewPanelActivityAssetSafe(self.TheatreManager.GetAdventureAssetItemIds(), self.PanelAssetitems, self, nil, XDataCenter.BiancaTheatreManager.AdventureAssetItemOnBtnClick)
    self:RegisterUiEvents()
    -- 当前节点 XUiBiancaTheatreNode
    self.CurrentNodeItems = {}
    self.BuffGrids = {}
    self.DownPanel = XUiBiancaTheatrePanelDown.New(self.PanelDown)
    self.FettersPanel = XUiBiancaTheatrePanelFetters.New(self.PanelFetters)
    self.VisionActive = false
    self.PanelVisionOff = XPanelPsionicVisionOff.New(self.PanelPsionicVisionOff, self)
    self.PanelVisionOn = XPanelPsionicVisionOn.New(self.PanelPsionicVisionOn, self)
    self:InitItemChange()
end

function XUiBiancaTheatrePlayMain:OnEnable()
    self.Super.OnEnable(self)
    XDataCenter.BiancaTheatreManager.CheckBgmPlay()

    self:Refresh()
    XDataCenter.BiancaTheatreManager.UpdateChapterBg(self.Bg)
    -- 处理下一个操作
    self.AdventureManager:ShowNextOperation(function()
        -- 特殊处理，有剧情节点时直接播放剧情到达下一步
        for _, node in ipairs(self.CurStep:GetCurrentNodes()) do
            if node:GetNodeType() == XBiancaTheatreConfigs.NodeType.Movie 
                and not node:GetIsPlayed() 
                and self.CurrentChapter:GetIsReady() then
                XDataCenter.MovieManager.PlayMovie(node:GetStoryId())
                node:RequestEnd(function()
                    if XLuaUiManager.IsUiShow("UiBiancaTheatrePlayMain") and self.GameObject then
                        self:Refresh()
                    end
                end)
                break
            end
        end
    end)
    -- 音效滤镜界限恢复
    XDataCenter.BiancaTheatreManager.StartAudioFilter()
    XEventManager.AddEventListener(XEventId.EVENT_BIANCA_THEATRE_VISION_OPEN, self.RefreshVision, self)
    XEventManager.AddEventListener(XEventId.EVENT_BIANCA_THEATRE_VISION_CHANGE, self.RefreshVision, self)
end

function XUiBiancaTheatrePlayMain:OnDisable()
    XEventManager.RemoveEventListener(XEventId.EVENT_BIANCA_THEATRE_VISION_OPEN, self.RefreshVision, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_BIANCA_THEATRE_VISION_CHANGE, self.RefreshVision, self)
end

function XUiBiancaTheatrePlayMain:OnDestroy()
    self.FettersPanel:Delete()
end

-- 按钮相关
--------------------------------------------------------------------------------

function XUiBiancaTheatrePlayMain:RegisterUiEvents()
    self.BtnMainUi.CallBack = function() XDataCenter.BiancaTheatreManager.RunMain() end
    XUiHelper.RegisterClickEvent(self, self.BtnBack, function ()
        XDataCenter.BiancaTheatreManager.ResetAudioFilter()
        self:Close()
    end)
    XUiHelper.RegisterHelpButton(self.BtnHelp, self.TheatreManager.GetHelpKey())
    XUiHelper.RegisterClickEvent(self, self.BtnTeam, self.OnBtnTeamClicked)
end

--货币点击方法
function XUiBiancaTheatrePlayMain:OnBtnClick(index)
    XLuaUiManager.Open("UiBiancaTheatreTips", XBiancaTheatreConfigs.TheatreInnerCoin)
end

function XUiBiancaTheatrePlayMain:OnBtnTeamClicked()
    XLuaUiManager.Open("UiBiancaTheatreMainMassage")
end

--------------------------------------------------------------------------------

-- 灵视相关
--------------------------------------------------------------------------------

function XUiBiancaTheatrePlayMain:SetVisionActive(active)
    self.VisionActive = active
    self:RefreshVision()
end

--------------------------------------------------------------------------------

-- 节点相关
--------------------------------------------------------------------------------

function XUiBiancaTheatrePlayMain:RefreshCurrentNodes()
    self.GridStage.gameObject:SetActiveEx(false)
    local child
    local childCount = self.PanelChooseStage.transform.childCount
    for i = 0, childCount - 1 do
        child = self.PanelChooseStage.transform:GetChild(i)
        child.gameObject:SetActiveEx(false)
    end
    local button
    local buttons = {}
    local nodes = self.CurStep:GetCurrentNodes()
    local node = nil
    self.CurrentNodeItems = {}
    for i = 1, #nodes do
        node = nodes[i]
        if i > childCount then
            child = XUiHelper.Instantiate(self.GridStage, self.PanelChooseStage.transform)
        else
            child = self.PanelChooseStage.transform:GetChild(i - 1)
        end
        child.gameObject:SetActiveEx(node:GetNodeType() ~= XBiancaTheatreConfigs.NodeType.Movie)
        button = child:GetComponent("XUiButton")
        button:SetDisable(node:GetIsDisable())
        table.insert(buttons, button)
        table.insert(self.CurrentNodeItems, XUiBiancaTheatreNode.New(child, self):SetData(node))
        -- 默认恢复已选中的状态
        if node:GetIsSelected() then
            button:SetButtonState(CS.UiButtonState.Select)
            self.CurrentNodeItems[i]:PlaySelectAnim()
        else
            self.CurrentNodeItems[i]:StopSelectAnim()
        end
    end
    self.PanelChooseStage:Init(buttons, function(index)
        self:OnNodeClicked(index)
    end)
end

function XUiBiancaTheatrePlayMain:OnNodeClicked(index)
    if self.CurStep:GetCurrentNodes()[index]:GetIsDisable() then
        return
    end
    for i, v in ipairs(self.CurrentNodeItems) do
        if index == i then
            self.CurrentNodeItems[i]:PlaySelectAnim()
        else
            self.CurrentNodeItems[i]:StopSelectAnim()
        end
    end
end

--------------------------------------------------------------------------------

-- Ui刷新相关
--------------------------------------------------------------------------------

function XUiBiancaTheatrePlayMain:Refresh()
    local chapterId = self.CurrentChapter:GetCurrentChapterId()
    self.CurStep = self.CurrentChapter:GetCurStep()
    -- 当前章节名
    self.TextTitle.text = self.CurrentChapter:GetTitle()
    -- 完成度
    self:UpdatePercent(chapterId)
    -- 刷新当前节点
    self:RefreshCurrentNodes()
    -- 灵视
    self:RefreshVision()
    -- 货币特效恢复
    self:RefreshItemChange()
    self.DownPanel:Refresh()
    self.FettersPanel:Refresh()
end

function XUiBiancaTheatrePlayMain:UpdatePercent(chapterId)
    local totalCount = XBiancaTheatreConfigs.GetChapterNodeTotalCount(chapterId)
    local passNodeCount = self.CurrentChapter:GetCurrentPassNodeCount()
    local percent = XTool.IsNumberValid(totalCount) and math.floor(passNodeCount / totalCount * 100) or 0
    if percent > 100 then
        percent = 100
        XLog.Warning(string.format("【肉鸽二期】当前章节的通关进度百分比超过了100；章节Id：%s，当前通关节点数：%s，总节点数：%s", chapterId, passNodeCount, totalCount))
    end
    self.TextPercent.text = string.format(XBiancaTheatreConfigs.GetClientConfig("PercentTitle"), percent)
end

function XUiBiancaTheatrePlayMain:RefreshVision()
    local adventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    local visionValue = adventureManager:GetVisionValue() or 0
    local visionId = XBiancaTheatreConfigs.GetVisionIdByValue(visionValue)
    local isVisionOpen = XDataCenter.BiancaTheatreManager.CheckVisionIsOpen()
    if isVisionOpen then
        XDataCenter.GuideManager.CheckGuideOpen()
    end
    if self.EffectVision then
        self.EffectVision.gameObject:LoadUiEffect(XBiancaTheatreConfigs.GetVisionUiEffectUrl(visionId))
        self.EffectVision.gameObject:SetActiveEx(isVisionOpen)
    end
    self.PanelVisionOff:SetActive(isVisionOpen and not self.VisionActive)
    self.PanelVisionOn:SetActive(isVisionOpen and self.VisionActive)
end

---货币栏位特效
function XUiBiancaTheatrePlayMain:RefreshItemChange()
    for index, _ in ipairs(XDataCenter.BiancaTheatreManager.GetAdventureAssetItemIds()) do
        if self["ItemChange" .. index] then
            self["ItemChange" .. index]:Refresh()
        end
    end
end

function XUiBiancaTheatrePlayMain:InitItemChange()
    self.PanelEnergyChange = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelEnergyChange")
    self.PanelEnergyChange2 = XUiHelper.TryGetComponent(self.Transform, "SafeAreaContentPane/PanelEnergyChange2")
    local panelEnergyChangeList = {
        self.PanelEnergyChange2,
        self.PanelEnergyChange,
    }
    for index, itemId in ipairs(XDataCenter.BiancaTheatreManager.GetAdventureAssetItemIds()) do
        if panelEnergyChangeList[index] then
            self["ItemChange" .. index] = XUiPanelItemChange.New(panelEnergyChangeList[index], itemId)
        end
    end
end

--------------------------------------------------------------------------------

return XUiBiancaTheatrePlayMain