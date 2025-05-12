local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")
--######################## XUiSelectRecruitTicketGrid ########################
local XUiSelectRecruitTicketGrid = XClass(nil, "XUiSelectRecruitTicketGrid")

function XUiSelectRecruitTicketGrid:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XUiHelper.InitUiClass(self, ui)

    self.Icon.gameObject:SetActiveEx(false)
    self:InitBtn()
    self:InitTap()
end

function XUiSelectRecruitTicketGrid:InitBtn()
    self.Btn.gameObject:SetActiveEx(false)
end

function XUiSelectRecruitTicketGrid:InitTap()
    if self.Tap then self.Tap.gameObject:SetActiveEx(false) end
    if self.Tap1 then self.Tap1.gameObject:SetActiveEx(false) end
    if self.Tap2 then self.Tap2.gameObject:SetActiveEx(false) end
    if self.Tap3 then self.Tap3.gameObject:SetActiveEx(false) end
    if self.Tap4 then self.Tap4.gameObject:SetActiveEx(false) end
end

--id：BiancaTheatreRecruitTicket表的Id
function XUiSelectRecruitTicketGrid:Refresh(id, isSelect)
    self.Id = id
    local quality = XBiancaTheatreConfigs.GetRecruitTicketQuality(id)
    --名字
    self.TxtDes.text = XBiancaTheatreConfigs.GetRecruitTicketName(id)
    local color = XBiancaTheatreConfigs.GetQualityTextColor(quality)
    if color then
        self.TxtDes.color = color
    end
    --描述
    self.TxtProgress.text = XBiancaTheatreConfigs.GetRecruitTicketDesc(id)
    --图标
    self.RImgIcon:SetRawImage(XBiancaTheatreConfigs.GetRecruitTicketIcon(id))
    --特殊标记
    if self.Tap then self.Tap.gameObject:SetActiveEx(XBiancaTheatreConfigs.IsShowRecruitTicketSpecialTag(id)) end
    --品质
    local quality = XBiancaTheatreConfigs.GetRecruitTicketQuality(id)
    self.ImgQuality:SetSprite(XArrangeConfigs.GeQualityPath(quality))

    --是否选中
    self:SetSelectActive(isSelect)
end

function XUiSelectRecruitTicketGrid:SetSelectActive(isActive)
    self.Select.gameObject:SetActiveEx(isActive)
end

function XUiSelectRecruitTicketGrid:GetId()
    return self.Id
end


--######################## XUiChoiceRecruitTicketPanel ########################
local XUiChoiceRecruitTicketPanel = XClass(nil, "XUiChoiceRecruitTicketPanel")

--招募券选择布局
function XUiChoiceRecruitTicketPanel:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XUiHelper.InitUiClass(self, ui)
end

function XUiChoiceRecruitTicketPanel:Init()
    self.DynamicTable = XDynamicTableNormal.New(self.Transform:GetComponent(typeof(CS.XDynamicTableNormal)))
    self.DynamicTable:SetProxy(XUiSelectRecruitTicketGrid)
    self.DynamicTable:SetDelegate(self)
    self.GridChallengeBanner.gameObject:SetActiveEx(false)
    self:RewriteRootUiFunc()
    self.GameObject:SetActiveEx(true)
end

--curStep：XAdventureStep
function XUiChoiceRecruitTicketPanel:Refresh()
    self.CurSelectGrid = nil
    self.AdventureManager = XDataCenter.BiancaTheatreManager.GetCurrentAdventureManager()
    self.CurChapter = self.AdventureManager:GetCurrentChapter()
    self.CurStep = self.CurChapter:GetCurStep()
    self.IdList = self.CurStep:GetTickIds()
    self.DynamicTable:SetDataSource(self.IdList)
    self.DynamicTable:ReloadDataASync()
end

local isSelect
function XUiChoiceRecruitTicketPanel:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        isSelect = self.CurSelectId == self.IdList[index] or false
        grid:Refresh(self.IdList[index], isSelect)
        if isSelect and not self.CurSelectGrid then
            self.CurSelectGrid = grid
        end
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_TOUCHED then
        self:ClickGridFunc(grid)
    end
end

function XUiChoiceRecruitTicketPanel:ClickGridFunc(grid)
    if self.CurSelectGrid then
        self.CurSelectGrid:SetSelectActive(false)
    end
    self.CurSelectGrid = grid
    self.CurSelectId = grid:GetId()
    grid:SetSelectActive(true)
end

--######################## 重写父UI按钮点击回调 ########################
function XUiChoiceRecruitTicketPanel:RewriteRootUiFunc()
    XUiHelper.RegisterClickEvent(self, self.RootUi.BtnNextStep, self.OnBtnNextStepClicked)
end

--点击下一步--选择招募券下一步是打开招募界面
function XUiChoiceRecruitTicketPanel:OnBtnNextStepClicked()
    local tickId = self.CurSelectId
    if not XTool.IsNumberValid(tickId) then
        XUiManager.TipError(XBiancaTheatreConfigs.GetClientConfig("NotSelectRecruitTicket"))
        return
    end
    self.CurChapter:RequestSelectRecruitTick(tickId, function(data)
        self.CurChapter:AddStep(data.Step)
        self.CurChapter:UpdateRecruitRoleDic()
        XLuaUiManager.PopThenOpen("UiBiancaTheatreRecruit")
    end)
end

return XUiChoiceRecruitTicketPanel