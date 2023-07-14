local XUiTRPGTaskTip = XLuaUiManager.Register(XLuaUi, "UiTRPGTaskTip")

local CSXTextManagerGetText = CS.XTextManager.GetText
local CSUnityEngineObjectInstantiate = CS.UnityEngine.Object.Instantiate
local next = next
local tableInsert = table.insert

local BTN_INDEX = {
    First = 1,
    Second = 2,
}

function XUiTRPGTaskTip:OnAwake()
    self:AutoAddListener()
    XEventManager.AddEventListener(XEventId.EVENT_TRPG_UPDATE_TARGET, self.Refresh, self)
end

function XUiTRPGTaskTip:OnStart()
    self:UpdateLeftTabBtns()
    self:InitSelect()
end

function XUiTRPGTaskTip:OnEnable()
    if self.SelectIndex then
        self.PanelNoticeTitleBtnGroup:SelectIndex(self.SelectIndex)
    end
end

function XUiTRPGTaskTip:OnDestroy()
    XEventManager.RemoveEventListener(XEventId.EVENT_TRPG_UPDATE_TARGET, self.Refresh, self)
end

function XUiTRPGTaskTip:AutoAddListener()
    self.BtnZhuizong.CallBack = function() self:OnBtnZhuizongClick() end
    self:RegisterClickEvent(self.BtnTanchuangCloseBig, self.Close)
end

function XUiTRPGTaskTip:InitSelect()
    local currTargetLinkId = XDataCenter.TRPGManager.GetCurrTargetLinkId()
    for btnIndex, targetTable in pairs(self.TabIndexDic) do
        if currTargetLinkId == targetTable.TargetLinkId then
            self.PanelNoticeTitleBtnGroup:SelectIndex(btnIndex)
            return
        end
    end
    self.PanelNoticeTitleBtnGroup:SelectIndex(1)
end

function XUiTRPGTaskTip:Refresh()
    local currTargetId = XDataCenter.TRPGManager.GetCurrTargetId()
    local isCurrTarget = self.SelectTargetId == currTargetId
    local targetLinkIsFinish = XDataCenter.TRPGManager.GetTargetLinkIsFinish(self.SelectTargetLinkId)

    self.TextName.text = targetLinkIsFinish and XTRPGConfigs.GetTargetLinkName(self.SelectTargetLinkId) or XTRPGConfigs.GetTargetName(self.SelectTargetId)
    self.TextInfo.text = XTRPGConfigs.GetTargetDesc(self.SelectTargetId, self.SelectTargetLinkId)

    if self.PanelFinish then
        self.PanelFinish.gameObject:SetActiveEx(targetLinkIsFinish)
    end

    if targetLinkIsFinish then
        self.BtnZhuizong.gameObject:SetActiveEx(false)
    else
        self.BtnZhuizong.gameObject:SetActiveEx(true)
        self.BtnZhuizong:SetDisable(isCurrTarget, not isCurrTarget)
    end

    --卡牌图标
    if self.ImgIcon then
        local cardIconPath = XTRPGConfigs.GetTargetCardIcon(self.SelectTargetId)
        if cardIconPath then
            self:SetUiSprite(self.ImgIcon, cardIconPath)
            self.ImgIcon.gameObject:SetActiveEx(true)
        else
            self.ImgIcon.gameObject:SetActiveEx(false)
        end
    end
end

function XUiTRPGTaskTip:UpdateLeftTabBtns()
    self.TabBtns = {}
    self.TabIndexDic = {}
    local btnIndex = 0
    local allCanFindTargetLink = XDataCenter.TRPGManager.GetAllCanFindTargetLink()
    local btnModel
    local btn
    local uiButton

    for missionType, targetTableList in ipairs(allCanFindTargetLink) do
        --一级标题
        btnModel = self:GetCertainBtnModel(BTN_INDEX.First, #targetTableList > 0)
        btn = CSUnityEngineObjectInstantiate(btnModel)
        btn.transform:SetParent(self.PanelNoticeTitleBtnGroup.transform, false)
        btn.gameObject:SetActiveEx(true)
        local name = XTRPGConfigs.GetTargetLinkMissionTypeName(missionType)
        btn:SetName(name)
        uiButton = btn:GetComponent("XUiButton")
        tableInsert(self.TabBtns, uiButton)
        btnIndex = btnIndex + 1

        --二级标题
        local firstIndex = btnIndex
        for i, targetTable in ipairs(targetTableList) do
            btnModel = self:GetCertainBtnModel(BTN_INDEX.Second, true, i, #targetTableList)
            btn = CSUnityEngineObjectInstantiate(btnModel)
            btn.transform:SetParent(self.PanelNoticeTitleBtnGroup.transform, false)
            btn.gameObject:SetActiveEx(true)
            btn:SetName(XTRPGConfigs.GetTargetLinkName(targetTable.TargetLinkId))
            uiButton = btn:GetComponent("XUiButton")
            uiButton.SubGroupIndex = firstIndex
            tableInsert(self.TabBtns, uiButton)
            btnIndex = btnIndex + 1
            self.TabIndexDic[btnIndex] = targetTable
        end
    end
    self.PanelNoticeTitleBtnGroup:Init(self.TabBtns, function(index) self:OnSelectedTog(index) end)
end

function XUiTRPGTaskTip:GetCertainBtnModel(index, hasChild, pos, totalNum)
    if index == BTN_INDEX.First then
        if hasChild then
            return self.BtnFirstHasSnd
        else
            return self.BtnFirst
        end
    elseif index == BTN_INDEX.Second then
        if totalNum == 1 then
            return self.BtnSecondAll
        end

        if pos == 1 then
            return self.BtnSecondTop
        elseif pos == totalNum then
            return self.BtnSecondBottom
        else
            return self.BtnSecond
        end
    end
end

function XUiTRPGTaskTip:OnSelectedTog(index)
    if self.SelectIndex == index then return end

    self.SelectIndex = index
    if self.TabIndexDic[index] then
        self.SelectTargetId = self.TabIndexDic[index]["TargetId"]
        self.SelectTargetLinkId = self.TabIndexDic[index]["TargetLinkId"]
    else
        --默认显示主线完成的标题和内容
        self.SelectTargetId = 0
        self.SelectTargetLinkId = 0
    end

    self:Refresh()
end

function XUiTRPGTaskTip:OnBtnZhuizongClick()
    XDataCenter.TRPGManager.RequestSelectTargetLinkSend(self.SelectTargetLinkId, false, true)
end