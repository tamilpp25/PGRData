local XUiPanelActivityAsset = require("XUi/XUiShop/XUiPanelActivityAsset")
local XDrawTabBtnEntity = require("XEntity/XDrawMianButton/XDrawTabBtnEntity")
local XNormalDrawGroupBtnEntity = require("XEntity/XDrawMianButton/XNormalDrawGroupBtnEntity")
local XLottoDrawGroupBtnEntity = require("XEntity/XDrawMianButton/XLottoDrawGroupBtnEntity")
local XUiDrawControl = require("XUi/XUiDraw/XUiDrawControl")
local XUiDrawScene = require("XUi/XUiDraw/XUiDrawScene")
local XUiNewGridDrawBanner = require("XUi/XUiDraw/XUiNewGridDrawBanner")

---@class XUiNewDrawMain:XLuaUi
---@field PanelNoticeTitleBtnGroup XUiButtonGroup
local XUiNewDrawMain = XLuaUiManager.Register(XLuaUi, "UiNewDrawMain")
local ServerDataReadyMaxCount = 1 --增加不同系统类型抽卡时记得酌情增加
local DEFAULT_UP_IMG = CS.XGame.ClientConfig:GetString("DrawDefaultUpImg")
local GUIDE_SHOW_GROUP = CS.XGame.ClientConfig:GetInt("GuideShowGroup")

function XUiNewDrawMain:OnStart(ruleType, groupId, defaultDrawId,groupIdPool)
    self.RuleType = ruleType
    self.DefaultGroupId = groupId
    --2.7支持多卡池查找
    if groupIdPool and type(groupIdPool)=='string' then
        --切割字符串
        local idStrs=string.Split(groupIdPool,'|')
        self.GroupIdPool={}
        for i, v in ipairs(idStrs) do
            table.insert(self.GroupIdPool,assert(tonumber(v)))
        end
    end
    
    if XLuaUiManager.IsUiShow("UiGuide") then
        self.DefaultGroupId = GUIDE_SHOW_GROUP
    end

    ---@type XUiComponent.XUiButton[]
    self.MainBtnList = {} -- 保存一级标签按钮物体，重复使用，在CreateMainBtn函数中，按钮不足时会生成按钮
    ---@type XUiComponent.XUiButton[]
    self.SubBtnList = {} -- 保存二级标签按钮物体，重复使用，在CreateSubBtn函数中，按钮不足时会生成按钮

    ---@type XUiNewGridDrawBanner
    self.CurBanner = nil
    self.BtnIndex = 0
    self.DefaultDrawId = defaultDrawId
    self.IsFirstIn = true
    self.CurrentSelectTemplateId = false
    
    --2.7处理多卡池情况
    self:FindDrawGroupId()

    self:InitScene()
    self:InitAssetPanel()
    self:InitBtn()
    self:InitWelfare()
    
    self:AddBtnListener()
    self:AddEventListener()
end

function XUiNewDrawMain:OnEnable()
    self:InitDrawCardsData()
    if self.CurBanner then
        self.CurBanner:Refresh()
    end
    -- 直接返回界面刷新
    if self.DrawInfo then
        --- 界面重新显示时，强制刷新辅助机模型，同步动画跟特效
        self.LastSceneId = nil
        self:RefreshScene()
    end
    -- 抽卡时等结束再弹窗
    if self._IsActivityTargetWaitDraw then
        self:_WhenDrawActivityStatusUpdate(self._UpdateTargetActivityType)
    end
end

function XUiNewDrawMain:OnDestroy()
    self:RemoveEventListener()
    self:MarkAllNewTag()
    XDataCenter.KickOutManager.Unlock(XEnumConst.KICK_OUT.LOCK.DRAW, false)
end

function XUiNewDrawMain:Refresh()
    if XTool.IsNumberValid(self.DefaultDrawId) then
        self:RefreshDefaultDrawId()
    else
        self:OnSelectUp(self.DrawInfo.Id)
        self:RefreshScene()
    end
    self:RefreshWelfare()
    self:RefreshPanelTwoForOne()
    self:_RefreshCharacterDrawTarget()
    self:UpdateBtnDiscount()
end

-- region 鬼泣五相关
function XUiNewDrawMain:RefreshPanelTwoForOne()
    local isDevilMayGroupId = XDataCenter.DrawManager:CheckIsDevilMayCryGroupId(self.GroupId)
    self.PanelTwoForOne.gameObject:SetActiveEx(isDevilMayGroupId)

    local canReceiveCount = XDataCenter.DrawManager:CheckIsCanReceiveCharacterByDrawId(self.DrawInfo.Id)
    self.PanelTwoForOne:GetObject("BtnReceive").gameObject:SetActiveEx(XTool.IsNumberValid(canReceiveCount))

    local leftCount = XDataCenter.DrawManager:GetLeftCanGetDevilCharacterCount(self.DrawInfo.Id)
    local textComponent = self.PanelTwoForOne:GetObject("TxtNum")
    textComponent.text = leftCount or 0
    textComponent.color = (XTool.IsNumberValid(leftCount)) and CS.UnityEngine.Color.white or CS.UnityEngine.Color.red
end

function XUiNewDrawMain:OnDevilMayCryBtnReceiveClick()
    local lfc, needRequestTaskList = XDataCenter.DrawManager:CheckIsCanReceiveCharacterByDrawId(self.DrawInfo.Id)
    if XTool.IsTableEmpty(needRequestTaskList) then
        return
    end
    XDataCenter.TaskManager.FinishMultiTaskRequest(needRequestTaskList, function (rewardList)
        XLuaUiManager.Open("UiDrawShowNew", self.DrawInfo, rewardList)
        self:RefreshPanelTwoForOne()
    end)
end
-- endregion 鬼泣五相关结束

function XUiNewDrawMain:UpdateDrawControl()
    if self.DrawControl then
        self.DrawControl:Update(self.DrawInfo, self.GroupId)
    end
end

--2.7针对多卡池，选定一个
function XUiNewDrawMain:FindDrawGroupId()
    if not XTool.IsTableEmpty(self.GroupIdPool) then
        local drawId = self.DefaultDrawId
        local exist=false
        for i, v in pairs(self.GroupIdPool) do --遍历每个卡池
            local infoList = XDataCenter.DrawManager.GetDrawGroupInfoByGroupId(v)
            if not XTool.IsTableEmpty(infoList) and not XTool.IsTableEmpty(infoList.OptionalDrawIdList) then
                if infoList.EndTime > 0 and infoList.EndTime - XTime.GetServerNowTimestamp()<=0 then
                    break
                end
                for _, info in pairs(infoList.OptionalDrawIdList) do
                    if info == drawId and not exist then
                        exist = true
                        self.DefaultGroupId=v
                        break
                    end
                end
            end
            if exist then break end
        end
    end
end

--region Data - DrawCardData & BtnGroupObj 
function XUiNewDrawMain:InitDrawCardsData()
    self.readyCount = 0
    self.NormalGroupInfoList = {}
    if not self.IsFirstIn then
        XDataCenter.DrawManager.GetDrawGroupList(function()
            self:_InitDrawCardsData()
        end)
    else
        self:_InitDrawCardsData()
        self.IsFirstIn = false
    end
end

function XUiNewDrawMain:_InitDrawCardsData()
    self.NormalGroupInfoList = XDataCenter.DrawManager.GetDrawGroupInfos()
    self:_CheckServerDataReady()
end

function XUiNewDrawMain:RefreshDefaultDrawId()
    if not XTool.IsNumberValid(self.DefaultDrawId) then
        return
    end

    local drawId = self.DefaultDrawId
    self.DefaultDrawId = nil
    local infoList = XDataCenter.DrawManager.GetDrawInfoListByGroupId(self.GroupId)
    local exist = false
    for _, info in pairs(infoList) do
        if info.Id == drawId then
            exist = true
            break
        end
    end
    -- 不存在研发
    if exist then
        XDataCenter.DrawManager.SaveDrawAimId(drawId, self.GroupId, function()
            self:OnSelectUp(drawId)
            self:RefreshScene()
        end)
    else
        XUiManager.TipText("EquipGuideDrawNoWeaponTip")
        self:OnSelectUp(self.DrawInfo.Id)
        self:RefreshScene()
    end
end

function XUiNewDrawMain:_CheckServerDataReady()
    --增加不同系统类型抽卡时记得检查“ServerDataReadyMaxCount”是否相应的增加
    self.readyCount = self.readyCount + 1
    if self.readyCount == ServerDataReadyMaxCount then
        self:_InitDrawTabs()
    end
end

function XUiNewDrawMain:_InitDrawTabs()
    self.BtnIndex = 1
    self.MainBtnCount = 1
    self.SubBtnCount = 1

    -- 保存一级标签（XDrawTabBtnEntity类）的字典与数组
    ---@type XDrawTabBtnEntity[]
    self.DrawTabDic = {}
    ---@type XDrawTabBtnEntity[]
    self.DrawTabList = {}
    ---@type table<number, XDrawTabBtnEntity|XDrawGroupBtnBaseEntity>
    self.AllTabEntityList = {} -- 保存所有标签类,包括一级、二级标签类
    ---@type XUiComponent.XUiButton[]
    self.AllBtnList = {} -- 保存所有标签按钮物体，包括一级、二级标签按钮物体

    self.SkipIndexDic = {} -- DrawGroupId对应ButtonGroup的索引

    self:_CreateDrawTabData(self.NormalGroupInfoList, XNormalDrawGroupBtnEntity) --普通抽卡
    self:_SortDrawTabData()
    self:_InitButtonGroup()
end

--- 初始化一级标签类，并保存其子标签类
---@param class XDrawGroupBtnBaseEntity
function XUiNewDrawMain:_CreateDrawTabData(groupInfoList, class)
    ----增加不同系统类型抽卡时页签生成需要添加对应的实体与初始化逻辑
    for _, drawGroupInfo in pairs(groupInfoList or {}) do

        local groupEntity = class.New() -- 生成组（二级标签）按钮用实体
        groupEntity:UpdateData(drawGroupInfo)

        if not self.DrawTabDic[groupEntity:GetTag()] then
            self.DrawTabDic[groupEntity:GetTag()] = XDrawTabBtnEntity.New(groupEntity:GetTag()) -- 生成类（一级标签）按钮用实体
            table.insert(self.DrawTabList, self.DrawTabDic[groupEntity:GetTag()])
        end

        self.DrawTabDic[groupEntity:GetTag()]:InsertDrawGroupList(groupEntity)
    end
end

function XUiNewDrawMain:_SortDrawTabData()
    table.sort(self.DrawTabList, function(a, b)
        return a:GetPriority() < b:GetPriority()
    end)
end

--- 初始化按钮组，选择默认标签
function XUiNewDrawMain:_InitButtonGroup()
    self:_BtnInit(self.MainBtnList)
    self:_BtnInit(self.SubBtnList)

    for _, drawTab in pairs(self.DrawTabList or {}) do
        local subgroupIndex = self:CreateMainBtn(drawTab)
        for _, drawGroupInfo in pairs(drawTab:GetDrawGroupList() or {}) do
            self:CreateSubBtn(subgroupIndex, drawGroupInfo)
        end
    end

    local curBtnIndex = 0
    local tmpGroupId = 0

    if self.DefaultGroupId then
        tmpGroupId = self.DefaultGroupId
        curBtnIndex = self:GetBtnIndexByGroupId(self.RuleType, tmpGroupId)
        self.DefaultGroupId = nil
    else
        if self.IsFirstIn then
            tmpGroupId = XDataCenter.DrawManager.GetGroupIdWithFreeTicket()
            if tmpGroupId == nil then
                tmpGroupId = XDataCenter.DrawManager.GetLostSelectDrawGroupId()
            end
            self.IsFirstIn = false
            curBtnIndex = self:GetBtnIndexByGroupId(XDrawConfigs.RuleType.Normal, tmpGroupId)
        else
            tmpGroupId = XDataCenter.DrawManager.GetLostSelectDrawGroupId()
            local tmptype = XDataCenter.DrawManager.GetLostSelectDrawType()
            curBtnIndex = self:GetBtnIndexByGroupId(tmptype, tmpGroupId)
        end
        if not curBtnIndex then
            local groupId = XDataCenter.DrawManager.GetGroupIdWithMaxOrder()
            curBtnIndex = self:GetBtnIndexByGroupId(self.RuleType, groupId)
        end
    end

    if curBtnIndex then
        local tagEntity = self.AllTabEntityList[curBtnIndex]
        if tagEntity and not tagEntity:IsMainButton() then
            -- 如果tagEntity为二级标签,则获取它所属的一级标签,然后判断是否可以打开
            local mainTagEntity = self.DrawTabDic[tagEntity:GetTag()]
            local isOpen = mainTagEntity:JudgeCanOpen(true)
            if not isOpen then
                curBtnIndex = 1
            end
        end
    else
        if tmpGroupId ~= 0 then
            XUiManager.TipText("NewDrawSkipNotInTime")
        end
        curBtnIndex = 1
    end

    self.PanelNoticeTitleBtnGroup:Init(self.AllBtnList, function(index)
        self:OnSelectedTog(index)
    end)
    self.PanelNoticeTitleBtnGroup:SelectIndex(self.AllBtnList[curBtnIndex] and curBtnIndex or 1)
end

---@param BtnList XUiComponent.XUiButton[]
function XUiNewDrawMain:_BtnInit(BtnList)
    for _, btn in pairs(BtnList or {}) do
        btn.gameObject:SetActiveEx(false)
        btn:SetButtonState(CS.UiButtonState.Normal)
        btn.TempState = CS.UiButtonState.Normal
        btn.IsFold = false --初始化时需要把按钮的状态已打开设置为false
    end
end

function XUiNewDrawMain:GetBtnIndexByGroupId(ruleType, groupId)
    local curBtnIndex = self.SkipIndexDic and
            self.SkipIndexDic[ruleType] and
            self.SkipIndexDic[ruleType][groupId]
    return curBtnIndex
end
--endregion

--region Ui - AssetPanel
function XUiNewDrawMain:InitAssetPanel()
    self.AssetActivityPanel = XUiPanelActivityAsset.New(self.PanelSpecialTool, self)
end

function XUiNewDrawMain:RefreshAssetPanel(index)
    local data = self.AllTabEntityList[index]
    self.AssetActivityPanel:Refresh(data:GetUseItemIdList())
    XDataCenter.ItemManager.AddCountUpdateListener(self.AllTabEntityList[self.CurSelectId]:GetUseItemIdList(),
            function()
                self.AssetActivityPanel:Refresh(self.AllTabEntityList[self.CurSelectId]:GetUseItemIdList())
            end, self.AssetActivityPanel)
end
--endregion

--region Ui - ShowBanner
---加载描述面板
function XUiNewDrawMain:CreateBanner(data)
    local groupActivityTargetData = XDataCenter.DrawManager.GetDrawGroupActivityTargetInfo(self.GroupId)
    local activeTargetId = groupActivityTargetData and groupActivityTargetData:GetActivityId()
    local drawInfo = XDataCenter.DrawManager.GetUseDrawInfoByGroupId(data:GetId())
    if XTool.IsNumberValid(activeTargetId) and not string.IsNilOrEmpty(XDrawConfigs.GetDrawActivityTargetShowBannerPrefab(activeTargetId)) then
        local prefab = self.PanelBanner:LoadPrefab(XDrawConfigs.GetDrawActivityTargetShowBannerPrefab(activeTargetId))
        self.CurBanner = XUiNewGridDrawBanner.New(prefab, data, self)
        self.CurBanner.GameObject.name = data:GetId()
    elseif drawInfo.Banner then
        local prefab = self.PanelBanner:LoadPrefab(drawInfo.Banner)
        self.CurBanner = XUiNewGridDrawBanner.New(prefab, data, self)
        self.CurBanner.GameObject.name = data:GetId()
    else
        local prefab = self.PanelBanner:LoadPrefab(data:GetBanner())
        self.CurBanner = XUiNewGridDrawBanner.New(prefab, data, self)
        self.CurBanner.GameObject.name = data:GetId()
    end

    if drawInfo.Resources then
        self.CurBanner:SetImage(drawInfo.Resources)
    end
end

function XUiNewDrawMain:GetRelationGroupData(id)
    local groupRelationDic = XDrawConfigs.GetDrawGroupRelationDic()
    local relationGroupId = groupRelationDic[id]
    if relationGroupId then
        for _, data in pairs(self.AllTabEntityList or {}) do
            if data:GetId() == relationGroupId then
                return data
            end
        end
    end
    return
end
--endregion

--region Ui - Mask 抽奖遮罩
function XUiNewDrawMain:MarkCurNewTag()
    if self.CurSelectId then
        self:_DoMark(self.CurSelectId)
    else
        XLog.Error("XUiNewDrawMain:MarkCurNewTag函数错误，self.CurSelectId为nil")
    end
end

function XUiNewDrawMain:MarkAllNewTag()
    for index = 1, self.BtnIndex do
        self:_DoMark(index)
    end
end

function XUiNewDrawMain:_DoMark(index)
    if self.AllTabEntityList[index] and self.AllBtnList[index] then
        if self.AllBtnList[index].SubGroupIndex > 0 and self.AllTabEntityList[index]:GetBannerBeginTime() > 0 then
            XDataCenter.DrawManager.MarkNewTag(self.AllTabEntityList[index]:GetBannerBeginTime(),
                    self.AllTabEntityList[index]:GetRuleType(),
                    self.AllTabEntityList[index]:GetId())
            self.AllBtnList[index]:ShowTag(false)
        end
    end
end
--endregion

--region Ui - Welfare
function XUiNewDrawMain:InitWelfare()
    self.TextWelfare = self.LabelWelfare:FindTransform("TextWelfare"):GetComponent("Text")
end

function XUiNewDrawMain:RefreshWelfare()
    if not self.LabelWelfare then
        return
    end
    local isBottomHintShow = self.DrawInfo.IsTriggerSpecified and self.DrawInfo.IsTriggerSpecified or false
    local isNewHandShow = self.DrawInfo.MaxBottomTimes == self.AllTabEntityList[self.CurSelectId]:GetNewHandBottomCount()
    if isBottomHintShow then
        self.TextWelfare.text = CS.XTextManager.GetText("NewDrawCalibration")
    end
    if isNewHandShow then
        self.TextWelfare.text = CS.XTextManager.GetText("NewDrawNewHand")
    end
    self.LabelWelfare.gameObject:SetActiveEx(isNewHandShow or isBottomHintShow)
end
--endregion

--region Ui - DrawActivityTarget
---@class GridDrawActivityTarget
---@field PanelAdd UnityEngine.Transform
---@field BtnAdd XUiComponent.XUiButton
---@field PanelSwitch UnityEngine.Transform
---@field BtnSwitch XUiComponent.XUiButton
---@field ImgRole UnityEngine.UI.Image
---@field ImgLevel UnityEngine.UI.Image
---@field TxtAPercent UnityEngine.UI.Text

function XUiNewDrawMain:InitDrawActivityTarget()
    ---@type GridDrawActivityTarget
    self._TargetBtnOptionalDrawObjDir = {}
    ---@type GridDrawActivityTarget
    self._TargetBtnTargetDrawObjDir = {}
    XTool.InitUiObjectByUi(self._TargetBtnOptionalDrawObjDir, self.CurBanner.TargetPanelSwitchA)
    XTool.InitUiObjectByUi(self._TargetBtnTargetDrawObjDir, self.CurBanner.TargetPanelSwitchS)

    -- 方法注册
    if self._TargetBtnOptionalDrawObjDir.BtnSwitch then
        self._TargetBtnOptionalDrawObjDir.BtnSwitch.CallBack = function()
            self:OnBtnOptionDrawClick()
        end
    end
    if self._TargetBtnOptionalDrawObjDir.ImgLevel then
        self._TargetBtnOptionalDrawObjDir.TxtAPercent = XUiHelper.TryGetComponent(self._TargetBtnOptionalDrawObjDir.ImgLevel.transform, "TxtPercent", "Text")
        local textPercentA = XUiHelper.TryGetComponent(self._TargetBtnOptionalDrawObjDir.TxtAPercent.transform, "TxtPercent2", "Text")
        if textPercentA then
            textPercentA.text = CS.XTextManager.GetText("PercentAText")
        end
    end
    if self._TargetBtnTargetDrawObjDir.BtnSwitch then
        self._TargetBtnTargetDrawObjDir.BtnSwitch.CallBack = function()
            self:OnBtnActivityTargetClick()
        end
        self._TargetBtnTargetDrawObjDir.BtnAdd.CallBack = function()
            self:OnBtnActivityTargetClick()
        end
    end
end

function XUiNewDrawMain:PlayDrawActivityTimeLineAnim()
    if self.CurBanner.PanelSwitchAEnable and not self._IsActivityTargetChange then
        self.CurBanner.PanelSwitchAEnable.transform:PlayTimelineAnimation()
    end
    if self.CurBanner.PanelSwitchSEnable and not self._IsNormalTargetChange then
        self.CurBanner.PanelSwitchSEnable.transform:PlayTimelineAnimation()
    end
    self._IsNormalTargetChange = false
    self._IsActivityTargetChange = false
end

function XUiNewDrawMain:_GetActivityTarget(groupId)
    local groupActivityTargetData = XDataCenter.DrawManager.GetDrawGroupActivityTargetInfo(groupId)
    if not groupActivityTargetData then
        return false
    end
    return groupActivityTargetData:GetTargetId()
end

function XUiNewDrawMain:_RefreshCharacterDrawTarget()
    local groupActivityTargetData = XDataCenter.DrawManager.GetDrawGroupActivityTargetInfo(self.GroupId)
    if not self.CurBanner or not self.CurBanner.TargetBtnDetails or not groupActivityTargetData then
        self:_RefreshBtnTag()
        return
    end
    
    self:InitDrawActivityTarget()
    self:PlayDrawActivityTimeLineAnim()
    local isHaveTarget = XTool.IsNumberValid(groupActivityTargetData:GetTargetId())
    
    -- rule按钮文本
    self.BtnOptionalDraw.gameObject:SetActiveEx(not self.CurBanner.TargetBtnDetails and not self:CheckIsNewDraw() and not XDataCenter.DrawManager:CheckIsDevilMayCryGroupId(self.GroupId))
    if self.CurBanner.TargetBtnDetails then
        local targetCount = groupActivityTargetData:GetTargetCount()
        local txt = isHaveTarget and XDrawConfigs.GetDrawActivityTargetShowActiveTipTxt(groupActivityTargetData:GetActivityId())
            or XDrawConfigs.GetDrawActivityTargetShowRuleTipTxt(groupActivityTargetData:GetActivityId())
        self.CurBanner.TargetBtnDetails:SetNameByGroup(0, XUiHelper.FormatText(txt, targetCount))
    end
    -- 原卡池按钮
    local combination = XDataCenter.DrawManager.GetDrawCombination(self.DrawInfo.Id)
    local characterIcon
    local levelIcon
    if not XTool.IsTableEmpty(combination.GoodsId) then
        local arrangeType = XArrangeConfigs.GetType(combination.GoodsId[1])
        if arrangeType == XArrangeConfigs.Types.Character then
            ---@type XCharacterAgency
            local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
            characterIcon = characterAgency:GetCharHalfBodyImage(combination.GoodsId[1])
        end
        levelIcon = XDrawConfigs.GetDrawClientConfig("DrawTargetAUpIcon", 2)
    else
        characterIcon = XDrawConfigs.GetDrawClientConfig("DrawTargetDefaultRoleImg")
        levelIcon = XDrawConfigs.GetDrawClientConfig("DrawTargetAUpIcon")
    end
    if not string.IsNilOrEmpty(characterIcon) and self._TargetBtnOptionalDrawObjDir.ImgRole then
        self._TargetBtnOptionalDrawObjDir.ImgRole:SetRawImage(characterIcon)
        if self._TargetBtnOptionalDrawObjDir.TxtAPercent then
            local drawAimProbability = XDrawConfigs.GetDrawAimProbability()
            self._TargetBtnOptionalDrawObjDir.TxtAPercent.text = drawAimProbability[self.DrawInfo.Id] and drawAimProbability[self.DrawInfo.Id].UpProbabilityPercent or ""
            self._TargetBtnOptionalDrawObjDir.TxtAPercent.gameObject:SetActiveEx(not XTool.IsTableEmpty(combination.GoodsId))
        end
    end
    if not string.IsNilOrEmpty(levelIcon) and self._TargetBtnOptionalDrawObjDir.ImgLevel then
        self._TargetBtnOptionalDrawObjDir.ImgLevel:SetSprite(levelIcon)
    end
    self:OnSelectTargetActivity(groupActivityTargetData)
    self:_RefreshBtnTag()
end

-- 刷新页签标签
function XUiNewDrawMain:_RefreshBtnTag()
    local groupTargetData
    for _, uiButton in ipairs(self.AllBtnList) do
        local btnObjDir = {}
        local data = self.AllTabEntityList[table.indexof(self.AllBtnList, uiButton)]
        XTool.InitUiObjectByUi(btnObjDir, uiButton.gameObject)
        local isShowTag = data:IsShowTag() and (not data:IsShowFreeTip())
        if data.DrawGroupList then  -- 一级页签
            for _, drawData in ipairs(data.DrawGroupList) do
                groupTargetData = XDataCenter.DrawManager.GetDrawGroupActivityTargetInfo(drawData.Id)
                if groupTargetData then
                    isShowTag = true
                end
            end
            uiButton:ShowTag(data:IsShowTag() and (not data:IsShowFreeTip()) or isShowTag)
        else                        -- 二级页签
            groupTargetData = XDataCenter.DrawManager.GetDrawGroupActivityTargetInfo(self.GroupId)
            if btnObjDir.PanelActivity and data:GetId() == self.GroupId then
                btnObjDir.PanelActivity.gameObject:SetActiveEx(not isShowTag and groupTargetData)
            end
        end
    end
end

---校准活动按钮刷新
---@param groupActivityTargetData XDrawActivityTargetInfo
function XUiNewDrawMain:OnSelectTargetActivity(groupActivityTargetData)
    if not groupActivityTargetData or not self.CurBanner.TargetBtnDetails then
        return
    end
    --这是一个物品id,集合N种物品,包括道具、人物、装备、辅助机等
    --因为是通过id规则分配类型的,所以要用XGoodsCommonManager.GetGoodsShowParamsByTemplateId处理一下
    local templateId = groupActivityTargetData:GetTargetId()
    local isHaveTemplateId = XTool.IsNumberValid(templateId)

    self.CurrentSTargetId = isHaveTemplateId and templateId or nil
    if self.CurBanner.RImgName then
        self.CurBanner.RImgName.gameObject:SetActiveEx(false)
    end
    if self._TargetBtnTargetDrawObjDir.PanelAdd then
        self._TargetBtnTargetDrawObjDir.PanelAdd.gameObject:SetActiveEx(not isHaveTemplateId)
    end
    if self._TargetBtnTargetDrawObjDir.PanelSwitch then
        self._TargetBtnTargetDrawObjDir.PanelSwitch.gameObject:SetActiveEx(isHaveTemplateId)
    end
    if not XTool.IsNumberValid(templateId) then
        return
    end
    local arrangeType = XArrangeConfigs.GetType(templateId)
    if arrangeType == XArrangeConfigs.Types.Character and self._TargetBtnTargetDrawObjDir.ImgRole then
        ---@type XCharacterAgency
        local characterAgency = XMVCA:GetAgency(ModuleId.XCharacter)
        local characterIcon = characterAgency:GetCharHalfBodyImage(templateId)
        self._TargetBtnTargetDrawObjDir.ImgRole:SetRawImage(characterIcon)
    end
    self:RefreshScene()
end

function XUiNewDrawMain:WhenDrawActivityStatusUpdate(tipType)
    self._UpdateTargetActivityType = tipType
    if XLuaUiManager.IsUiShow(self.Name) then
        self:Refresh()
        self:RefreshScene()
        self:_WhenDrawActivityStatusUpdate(self._UpdateTargetActivityType)
    else
        self._IsActivityTargetWaitDraw = true
    end
end

function XUiNewDrawMain:_WhenDrawActivityStatusUpdate(tipType)
    if tipType == XDrawConfigs.DrawTargetTipType.Open then
        XUiManager.TipErrorWithKey("DrawTargetActivityOpen")
    elseif tipType == XDrawConfigs.DrawTargetTipType.Close then
        XUiManager.TipErrorWithKey("DrawTargetActivityClose")
    elseif tipType == XDrawConfigs.DrawTargetTipType.Update then
        XUiManager.TipErrorWithKey("DrawTargetActivityUpdate")
    end
    self._IsActivityTargetWaitDraw = false
end
--endregion

--region Ui - MainTagGroup
--- 初始化一级标签按钮物体
---@param data XDrawTabBtnEntity
function XUiNewDrawMain:CreateMainBtn(data)
    local uiButton = self.MainBtnList[self.MainBtnCount]
    if not uiButton then
        local obj = CS.UnityEngine.Object.Instantiate(self.BtnFirst)
        obj.name = "TabBtn"..data:GetId()
        uiButton = obj:GetComponent("XUiButton")
        self.MainBtnList[self.MainBtnCount] = uiButton
    end

    -- 校准一级页签
    local groupTargetData
    local isShowTag = false
    local isDevilCanReceive = false
    for _, drawData in ipairs(data.DrawGroupList) do
        groupTargetData = XDataCenter.DrawManager.GetDrawGroupActivityTargetInfo(drawData.Id)
        if groupTargetData then
            isShowTag = true
        end
        if XDataCenter.DrawManager.CheckIsCanReceiveCharacterByDrawId(drawData.Id) then
            isDevilCanReceive = true
        end
    end
    if uiButton then
        uiButton.gameObject:SetActiveEx(true)
        uiButton.transform:SetParent(self.transform, false)
        uiButton.transform:SetParent(self.PanelNoticeTitleBtnGroup.transform, false)
        local IsUnLock = data:JudgeCanOpen(false)
        uiButton:SetDisable(not IsUnLock)
        uiButton:SetNameByGroup(0, IsUnLock and (string.format("0%d", data:GetTxtName1())) or "")
        uiButton:SetNameByGroup(1, data:GetTxtName2())
        uiButton:SetNameByGroup(2, data:GetTxtName3())
        uiButton:SetRawImage(data:GetTabBg())
        uiButton:ShowTag(data:IsShowTag() and (not data:IsShowFreeTip()) or isShowTag)
        uiButton:ShowReddot(data:IsShowFreeTip())
        uiButton.transform:FindTransform("TagReceive").gameObject:SetActiveEx(isDevilCanReceive)
        table.insert(self.AllBtnList, uiButton)
        table.insert(self.AllTabEntityList, data)
    end
    local subGroupIndex = self.BtnIndex
    self.BtnIndex = self.BtnIndex + 1
    self.MainBtnCount = self.MainBtnCount + 1
    return subGroupIndex
end

--- 一级标签的按钮状态为Disable时传入的index为它自己的index，否则为它的第一个子标签的index
--- 只有一级标签类才会判断是否能打开卡池
function XUiNewDrawMain:OnSelectedTog(index)
    ---@type XUiComponent.XUiButton
    local btn = self.AllBtnList[index]
    ---@type XDrawTabBtnEntity
    local entity = self.AllTabEntityList[btn.SubGroupIndex > 0 and btn.SubGroupIndex or btn.GroupIndex]
    if entity and not XMVCA.XSubPackage:CheckSubpackage(XEnumConst.SUBPACKAGE.ENTRY_TYPE.DRAW, entity:GetId()) then
        self.PanelNoticeTitleBtnGroup:SelectIndex(self.CurSelectId or 1, false)
        return
    end
    if self.AllTabEntityList[index] then
        local IsTypeTab = self.AllTabEntityList[index]:GetRuleType() == XDrawConfigs.RuleType.Tab
        self.RuleType = not IsTypeTab and
                self.AllTabEntityList[index]:GetRuleType() or self.RuleType
        if not IsTypeTab then
            XDataCenter.DrawManager.SetLostSelectDrawGroupId(self.AllTabEntityList[index]:GetId())
            XDataCenter.DrawManager.SetLostSelectDrawType(self.RuleType)
        end
        if self.AllTabEntityList[index]:IsMainButton() then
            if not self.AllTabEntityList[index]:JudgeCanOpen(true) then
                return
            end
            self.GroupId = self.AllTabEntityList[index].DrawGroupList[1].Id
        else
            self.GroupId = self.AllTabEntityList[index]:GetId()
        end
        self.CurSelectId = index
        XDataCenter.DrawManager.GetDrawInfoList(self.GroupId, function()
            local drawInfo = XDataCenter.DrawManager.GetUseDrawInfoByGroupId(self.GroupId)
            self.DrawInfo = drawInfo
			--选择卡池事件，将当前选择的卡池Id广播出去
            XEventManager.DispatchEvent(XEventId.EVENT_DRAW_SELECT,self.DrawInfo.Id)
            self.AllTabEntityList[index].MaxBottomTimes = self.DrawInfo.MaxBottomTimes
            self.AllTabEntityList[index].BottomTimes = self.DrawInfo.BottomTimes
            self.AllTabEntityList[index]:DoSelect(self)
            self:UpdatePurchase()
            if not self.DrawControl then
                ---@type XUiDrawControl
                self.DrawControl = XUiDrawControl.New(self, drawInfo, function()
                end, self)
            end
            self.DrawControl:Update(drawInfo, self.GroupId)
            self:Refresh()
            self:CheckAutoOpen()
            self:RefreshAssetPanel(index)
        end)
    end
end

--- 选择第一个页签
function XUiNewDrawMain:SelectFirstTab()
    local groupId = XDataCenter.DrawManager.GetGroupIdWithMaxOrder()
    local curBtnIndex = self:GetBtnIndexByGroupId(self.RuleType, groupId)
    if curBtnIndex then
        self.PanelNoticeTitleBtnGroup:SelectIndex(curBtnIndex)
    end
end
--endregion

--region Ui - SecondTagGroup
--- 初始化二级标签按钮物体
---@param subGroupIndex any
---@param data XNormalDrawGroupBtnEntity
function XUiNewDrawMain:CreateSubBtn(subGroupIndex, data)
    local uiButton = self.SubBtnList[self.SubBtnCount]
    local btnObjDir = {}
    if not uiButton then
        local obj = CS.UnityEngine.Object.Instantiate(self.BtnChild)
        XTool.InitUiObjectByUi(btnObjDir, obj)
        obj.name = data:GetId()
        uiButton = obj:GetComponent("XUiButton")
        self.SubBtnList[self.SubBtnCount] = uiButton
    end

    -- 校准二级页签
    local groupTargetData = XDataCenter.DrawManager.GetDrawGroupActivityTargetInfo(data:GetId())
    if uiButton then
        uiButton.gameObject:SetActiveEx(true)
        uiButton.transform:SetParent(self.transform, false)
        uiButton.transform:SetParent(self.PanelNoticeTitleBtnGroup.transform, false)
        local uiObject = uiButton.transform:GetComponent("UiObject")
        uiButton:SetName(data:GetName())
        uiButton:SetRawImage(data:GetGroupBtnBg())
        uiButton.SubGroupIndex = subGroupIndex
        uiObject:GetObject("A").gameObject:SetActiveEx(data:GetRareRank() == XDrawConfigs.RareRank.A)
        uiObject:GetObject("S").gameObject:SetActiveEx(data:GetRareRank() == XDrawConfigs.RareRank.S)

        XDataCenter.DrawManager.GetDrawInfoList(data.Id, function ()
            local drawInfo = XDataCenter.DrawManager.GetUseDrawInfoByGroupId(data.Id) -- data.Id就是GroupId
            local isCanReceive = XDataCenter.DrawManager:CheckIsCanReceiveCharacterByDrawId(drawInfo and drawInfo.Id)
            uiObject:GetObject("TagReceive").gameObject:SetActiveEx(XTool.IsNumberValid(isCanReceive))
            uiObject:GetObject("TagDiscount").gameObject:SetActiveEx(XDataCenter.DrawManager:CheckIsDevilMayCryGroupId(data.Id))
        end)

        self.SkipIndexDic[data:GetRuleType()] = self.SkipIndexDic[data:GetRuleType()] or {}
        self.SkipIndexDic[data:GetRuleType()][data:GetId()] = self.BtnIndex

        uiButton:ShowReddot(data:IsShowFreeTip())
        
        local isShowTag = data:IsShowTag() and (not data:IsShowFreeTip())
        -- 有tag优先显示tag
        uiButton:ShowTag(isShowTag)
        -- 无tag显示校准
        if btnObjDir.PanelActivity then
            btnObjDir.PanelActivity.gameObject:SetActiveEx(not isShowTag and groupTargetData)
        end

        table.insert(self.AllBtnList, uiButton)
        table.insert(self.AllTabEntityList, data)
    end
    self.BtnIndex = self.BtnIndex + 1
    self.SubBtnCount = self.SubBtnCount + 1
end
--endregion

--region Ui - DrawUpSelect
---检查自动弹窗概率up选择
function XUiNewDrawMain:CheckAutoOpen()
    if self.CurDrawType ~= XDrawConfigs.CombinationsTypes.Aim then
        return
    end

    if XDataCenter.DrawManager:CheckIsDevilMayCryGroupId(self.GroupId) then
        return
    end

    local IsHaveActivty = false
    local activtyTime = 0
    local groupInfo = XDataCenter.DrawManager.GetDrawGroupInfoByGroupId(self.GroupId)
    local drawInfoList = XDataCenter.DrawManager.GetDrawInfoListByGroupId(self.GroupId)
    for _, drawInfo in pairs(drawInfoList) do
        if drawInfo.StartTime > 0 then
            IsHaveActivty = true
            if drawInfo.StartTime > activtyTime then
                activtyTime = drawInfo.StartTime
            end
        end
    end

    local IsCanActivtyOpen = IsHaveActivty and XDataCenter.DrawManager.IsCanAutoOpenAimGroupSelect(activtyTime, self.GroupId)
    if IsCanActivtyOpen or (groupInfo.MaxSwitchDrawIdCount > 0 and groupInfo.UseDrawId == 0) and (not XLuaUiManager.IsUiLoad("UiDrawOptional")) then
        -- 2.13优化 组合数量为1时，首次进入不弹出概率提升的窗口
        if #groupInfo.OptionalDrawIdList > 1 and not self:CheckIsNewDraw() then
            self:OnBtnOptionDrawClick()
        end
    end
end

function XUiNewDrawMain:CheckIsNewDraw()
    return XDataCenter.DrawManager:CheckIsNewDraw(self.GroupId)
end

function XUiNewDrawMain:OnSelectUp(drawId)
    local drawInfo = XDataCenter.DrawManager.GetDrawInfo(drawId)
    self.DrawInfo = drawInfo
    self:UpdatePurchase()
    self.DrawControl:Update(drawInfo, self.GroupId)
    local combination = XDataCenter.DrawManager.GetDrawCombination(drawInfo.Id)
    if not combination then
        self.BtnOptionalDraw.gameObject:SetActiveEx(false)
        return
    end
    self.CurDrawType = combination.Type
    self.BtnOptionalDraw.gameObject:SetActiveEx(not self:CheckIsNewDraw() and not XDataCenter.DrawManager:CheckIsDevilMayCryGroupId(self.GroupId))
    local drawAimProbability = XDrawConfigs.GetDrawAimProbability()
    if drawAimProbability[drawId] then
        self.TxtProbability.text = drawAimProbability[drawId].UpProbability or ""
    end
    if not combination.GoodsId[1] then
        self.ImgQuality.gameObject:SetActiveEx(false)
        self.RImgRole:SetRawImage(DEFAULT_UP_IMG)
        self.AllTabEntityList[self.CurSelectId]:DoSelect(self)
        self.CurBanner:UpdateNewDrawChar(DEFAULT_UP_IMG, false)
        self.CurrentSelectTemplateId = nil
        return
    end
    self.CurrentSelectTemplateId = combination.GoodsId[1]
    self.GoodsShowParams = XGoodsCommonManager.GetGoodsShowParamsByTemplateId(self.CurrentSelectTemplateId)

    self.RImgRole:SetRawImage(self.GoodsShowParams.Icon)
    if self.GoodsShowParams.QualityIcon then
        self:SetUiSprite(self.ImgQuality, self.GoodsShowParams.QualityIcon)
    end
    local isShowQuality = not string.IsNilOrEmpty(self.GoodsShowParams.QualityIcon)
    self.ImgQuality.gameObject:SetActiveEx(isShowQuality)
    self.AllTabEntityList[self.CurSelectId]:DoSelect(self)

    -- 播放切换特效
    self.Effect2.gameObject:SetActive(false)
    self.Effect2.gameObject:SetActive(true)

    self.CurBanner:UpdateNewDrawChar(self.GoodsShowParams.Icon, isShowQuality, self.GoodsShowParams.QualityIcon)
end
--endregion

--region Ui - Purchase
function XUiNewDrawMain:UpdatePurchase()
    if self.DrawInfo then
        if self.DrawInfo.PurchaseId and next(self.DrawInfo.PurchaseId) then
            self.BtnDrawPurchaseLB.gameObject:SetActiveEx(true)
            if self.DrawInfo.PurchaseUiType and self.DrawInfo.PurchaseUiType ~= 0 then
                local uiType = self.DrawInfo.PurchaseUiType
                XDataCenter.PurchaseManager.GetPurchaseListRequest(uiType)
            end
        else
            self.BtnDrawPurchaseLB.gameObject:SetActiveEx(false)
        end
    end
end
--endregion

--region Ui - BtnListener
function XUiNewDrawMain:InitBtn()
    self.BtnFirst.gameObject:SetActiveEx(false)
    self.BtnChild.gameObject:SetActiveEx(false)
end

function XUiNewDrawMain:AddBtnListener()
    self.BtnMainUi.CallBack = function()
        self:OnBtnMainUiClick()
    end
    self.BtnBack.CallBack = function()
        self:OnBtnBackClick()
    end
    self.BtnOptionalDraw.CallBack = function()
        self:OnBtnOptionDrawClick()
    end
    self.BtnDrawPurchaseLB.CallBack = function()
        self:OnBtnLBClick()
    end
    self.BtnDrawRecord.CallBack = function()
        self:OnBtnDrawRecordClick()
    end

    self.PanelTwoForOne:GetObject("BtnReceive").CallBack = function()
        self:OnDevilMayCryBtnReceiveClick()
    end
end

function XUiNewDrawMain:OnBtnBackClick()
    self:Close()
end

function XUiNewDrawMain:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiNewDrawMain:OnBtnOptionDrawClick()
    self:StopAnimationToEnd(self.CurBanner.PanelSwitchAEnable)
    self:StopAnimationToEnd(self.CurBanner.PanelSwitchSEnable)

    self.LastSceneId = nil
    self._IsNormalTargetChange = true
    XLuaUiManager.Open("UiDrawOptional", self,
            function(drawId)
                self:OnSelectUp(drawId)
                self:RefreshScene()
            end,
            function()
                self:Close()
            end,
            function()
                self:SelectFirstTab()
            end)
end

function XUiNewDrawMain:OnBtnLBClick()
    self:OpenChildUi("UiDrawPurchaseLB", self)
end

function XUiNewDrawMain:OnBtnDrawRecordClick()
    XDataCenter.DrawManager.RequestDrawGetHistoryGroupList(function(historyGroupInfos)
        XLuaUiManager.Open('UiDrawRecord', self.GroupId, historyGroupInfos)
    end)
end

function XUiNewDrawMain:OnBtnActivityTargetClick()
    self:StopAnimationToEnd(self.CurBanner.PanelSwitchAEnable)
    self:StopAnimationToEnd(self.CurBanner.PanelSwitchSEnable)

    self._IsActivityTargetChange = true
    XLuaUiManager.Open("UiDrawOptional", self,
            function(groupActivityTargetData)
                self:OnSelectTargetActivity(groupActivityTargetData)
            end,
            function()
                self:Close()
            end,
            nil, true)
end

function XUiNewDrawMain:StopAnimationToEnd(anim)
    if anim and anim.time < anim.duration then
        anim:Stop()
        anim.time = anim.duration
        anim:Evaluate()
    end
end
--endregion

-- region Detail

function XUiNewDrawMain:CheckIsSelectUp()
    if not self.CurBanner then
        return false, false
    end

    local isShow = false

    if self.CurBanner.Data then
        isShow = XDataCenter.DrawManager.CheckIsShowOptionDraw(self.CurBanner.Data:GetId())
    end

    if self.CurBanner.IsMultipleUp then
        return XTool.IsNumberValid(self.CurrentSelectTemplateId) or XTool.IsNumberValid(self.CurrentSTargetId), isShow
    end

    return XTool.IsNumberValid(self.CurrentSelectTemplateId), isShow
end


function XUiNewDrawMain:GetCurrentSelectUpTargetId()
    if self.CurBanner.IsMultipleUp and XTool.IsNumberValid(self.CurrentSTargetId) then
        return self.CurrentSTargetId
    else
        return self.CurrentSelectTemplateId
    end
end

-- endregion

--region Event
function XUiNewDrawMain:AddEventListener()
    XEventManager.AddEventListener(XEventId.EVENT_DRAW_FREE_TICKET_UPDATE, self.UpdateDrawControl, self)
    XEventManager.AddEventListener(XEventId.EVENT_DRAW_TARGET_ACTIVITY_CHANGE, self.WhenDrawActivityStatusUpdate, self)
end

function XUiNewDrawMain:RemoveEventListener()
    XEventManager.RemoveEventListener(XEventId.EVENT_DRAW_FREE_TICKET_UPDATE, self.UpdateDrawControl, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_DRAW_TARGET_ACTIVITY_CHANGE, self.WhenDrawActivityStatusUpdate, self)
end
--endregion

--region Scene
function XUiNewDrawMain:InitScene()
    ---@type XUiDrawScene
    self.DrawScene = XUiDrawScene.New(self)
end

function XUiNewDrawMain:RefreshScene()
    local targetId = self:_GetActivityTarget(self.GroupId)
    if self.LastSceneId == self.DrawInfo.Id and self._LastActivityTargetId == targetId then
        return
    end
    self.LastSceneId = self.DrawInfo.Id
    local drawSceneCfg = XDrawConfigs.GetDrawSceneCfg(self.DrawInfo.Id)
    if not drawSceneCfg then
        return
    end
    self._LastActivityTargetId = targetId
    self.DrawScene:RefreshScene(drawSceneCfg, XTool.IsNumberValid(targetId) and targetId)
    self.CurBanner:UpdateNewDrawView(drawSceneCfg, XTool.IsNumberValid(targetId) and targetId)
end
--endregion

--region 武器阶段展示

function XUiNewDrawMain:HideOrShowOthers(isShow)
    if not self._SafeAreaContentPane then
        self._SaftAreaContenPane = self.Transform:Find("SafeAreaContentPane")
    end
    self._SaftAreaContenPane.gameObject:SetActiveEx(isShow)
end

--endregion

--region 新活动卡池

function XUiNewDrawMain:UpdateBtnDiscount()
    local isShowDiscount = XDataCenter.DrawManager:CheckIsShowDiscount(self.GroupId)
    if self.PanelDiscount1 then
        self.PanelDiscount1.gameObject:SetActiveEx(isShowDiscount)
    end
    if self.PanelDiscount2 then
        self.PanelDiscount2.gameObject:SetActiveEx(isShowDiscount)
    end
end

--endregion