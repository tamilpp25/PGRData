local XUiFubenNierRepeat = XLuaUiManager.Register(XLuaUi, "UiFubenNierRepeat")
local XUiNieRLineBanner = require("XUi/XUiNieR/XUiRepeat/XUiNierRepeatLineBanner")

function XUiFubenNierRepeat:OnAwake()

    self.BtnBack.CallBack = function() self:OnBtnBackClick() end
    self.BtnMainUi.CallBack = function() self:OnBtnMainUiClick() end

    self.BtnTeam.CallBack = function() self:OnBtnTeamClick() end
    self.BtnPOD.CallBack = function() self:OnBtnPODClick() end
    self.BtnRenWu.CallBack = function() self:OnBtnRenWuClick() end
    self.BtnShop.CallBack = function() self:OnBtnShopClick() end
    self:BindHelpBtn(self.BtnHelp, "NierRepeatHelp")
    self.BtnTeam.gameObject:SetActiveEx(false)
    self.BtnPOD.gameObject:SetActiveEx(false)
    self.BtnRenWu.gameObject:SetActiveEx(false)
    self.BtnShop.gameObject:SetActiveEx(false)

    -- self.AssetPanel = XUiPanelAsset.New(self, self.PanelAsset, XDataCenter.NieRManager.GetRepeatStageConsumeId())
    -- self.AssetPanel:RegisterJumpCallList({[1] = function()
    --     self:OnTickJumpClick()
    -- end })
    self:InitAssetPanel()
    self.XUiNieRLineBanner = XUiNieRLineBanner.New(self.UiFubenMainLineBanner, self)
    -- self.UiNierMainLineBanner:UpdateData()
    
end

function XUiFubenNierRepeat:OnStart(paramId)
    self.NeedJumpId = paramId
    self:AddRedPointEvent()
end

function XUiFubenNierRepeat:OnEnable()
    if XDataCenter.NieRManager.GetIsActivityEnd() then
        XScheduleManager.ScheduleOnce(function()
            if not self.GameObject or  not self.GameObject:Exist() then return end
            XDataCenter.NieRManager.OnActivityEnd()
        end, 1)
    else
        local unlockCount,count = XDataCenter.NieRManager.GetCharacterCount()
        local nierPOD = XDataCenter.NieRManager.GetNieRPODData()
        -- self.BtnTeam:SetNameByGroup(0, CS.XTextManager.GetText("NieRBtnTeamNameStr"))
        -- self.BtnPOD:SetNameByGroup(0, CS.XTextManager.GetText("NieRBtnPODNameStr"))  
        -- self.BtnRenWu:SetNameByGroup(0, CS.XTextManager.GetText("NieRBtnRenWuNameStr"))
        -- self.BtnShop:SetNameByGroup(0, CS.XTextManager.GetText("NieRBtnShopNameStr"))  
    
        -- self.BtnTeam:SetNameByGroup(1, string.format("%s/%s",unlockCount, count))
        -- self.BtnPOD:SetNameByGroup(1, string.format("Lv.%s",nierPOD:GetNieRPODLevel()))  
        self.XUiNieRLineBanner:UpdateData(self.NeedJumpId)
        self.NeedJumpId = nil
        XDataCenter.NieRManager.CheckNieRCharacterAbilityOpen()
    end
end

function XUiFubenNierRepeat:OnDisable()
end

function XUiFubenNierRepeat:OnDestroy()
end

function XUiFubenNierRepeat:InitAssetPanel()
    local PanelTool1 = XUiHelper.TryGetComponent(self.PanelAsset.transform, "PanelTool1", nil)
    local RImgTool1 = XUiHelper.TryGetComponent(self.PanelAsset.transform, "PanelTool1/RImgTool1", "RawImage")
    self.TxtTool1 = XUiHelper.TryGetComponent(self.PanelAsset.transform, "PanelTool1/TxtTool1", "Text")
    self.BtnBuyJump1 = XUiHelper.TryGetComponent(self.PanelAsset.transform, "PanelTool1/BtnBuyJump1", "Button")
    if self.BtnBuyJump1 then
        XUiHelper.RegisterClickEvent(self, self.BtnBuyJump1, self.OnTickJumpClick)
    end
    
    local itemId = XDataCenter.NieRManager.GetRepeatStageConsumeId()
    local item = XDataCenter.ItemManager.GetItem(itemId)

    if RImgTool1 ~= nil and RImgTool1:Exist() then
        RImgTool1:SetRawImage(item.Template.Icon, nil, false)
    end

    local func = function(textTool, id)
        local itemCount = XDataCenter.ItemManager.GetCount(id)
        textTool.text = itemCount .. "/" .. XDataCenter.NieRManager.GetNieRRepeatConsumeMaxCount()
    end
    local f = function()
        func(self.TxtTool1, itemId)
    end
    XDataCenter.ItemManager.AddCountUpdateListener(itemId, f, self.TxtTool1)
    func(self.TxtTool1, itemId)
end

function XUiFubenNierRepeat:OnTickJumpClick()
    local item = XDataCenter.ItemManager.GetItem(XDataCenter.NieRManager.GetRepeatStageConsumeId())
    local data = {
        Id = item.Id,
        Count = item ~= nil and tostring(item.Count) or "0"
    }
    XLuaUiManager.Open("UiTip", data)   
end

--添加点事件
function XUiFubenNierRepeat:AddRedPointEvent()
    -- XRedPointManager.AddRedPointEvent(self.BtnRenWu, self.RefreshTaskRedDot, self,{ XRedPointConditions.Types.CONDITION_NIER_TASK_RED }, -1)
    -- XRedPointManager.AddRedPointEvent(self.BtnTeam, self.RefreshTeamRedDot, self,{ XRedPointConditions.Types.CONDITION_NIER_CHARACTER_RED }, {CharacterId = -1, IsInfor = true, IsTeach = true})
    -- XRedPointManager.AddRedPointEvent(self.BtnPOD, self.RefreshPODRedDot, self,{ XRedPointConditions.Types.CONDITION_NIER_POD_RED })
end

--任务按钮红点
function XUiFubenNierRepeat:RefreshTaskRedDot(count)
    self.BtnRenWuRed.gameObject:SetActiveEx(count >= 0)
end

--尼尔角色按钮红点
function XUiFubenNierRepeat:RefreshTeamRedDot(count)
    self.BtnTeamRed.gameObject:SetActiveEx(count >= 0)
end

--辅助机按钮红点
function XUiFubenNierRepeat:RefreshPODRedDot(count)
    self.BtnPODRed.gameObject:SetActiveEx(count >= 0)
end

function XUiFubenNierRepeat:OnBtnBackClick()
    self:Close()
end

function XUiFubenNierRepeat:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiFubenNierRepeat:OnBtnTeamClick()
    XLuaUiManager.Open("UiNierCharacterSel")
end

function XUiFubenNierRepeat:OnBtnPODClick()
    XLuaUiManager.Open("UiFuBenNierWork")
end

function XUiFubenNierRepeat:OnBtnRenWuClick()
    local skipId = self.XUiNieRLineBanner:GetNieRRepeatTaskSkipId()
    if skipId and skipId ~= 0 then
        XFunctionManager.SkipInterface(skipId)
    else
        XLuaUiManager.Open("UiNierTask")
    end
end

function XUiFubenNierRepeat:OnBtnShopClick()
    if XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopCommon)
    or XFunctionManager.DetectionFunction(XFunctionManager.FunctionName.ShopActive) then
        XLuaUiManager.Open("UiNierShop")
    end
end

function XUiFubenNierRepeat:OnBtnChapterClick(stageId, nierRepeatStageId)
    XLuaUiManager.Open("UiFubenNierGuanqiaNormal", stageId, XNieRConfigs.NieRStageType.RepeatStage, nierRepeatStageId)
    XDataCenter.NieRManager.SaveSelRepeatStageId(nierRepeatStageId)
end