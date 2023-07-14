local TEAM_MEMBER_ORDER = {2, 1, 3} --队伍顺序（蓝，红，黄）

local XUiGridReplace = require("XUi/XUiPartner/PartnerPreset/UiPartnerPopup/XUiGridReplace")
local XUiGridChange = require("XUi/XUiPartner/PartnerPreset/UiPartnerPopup/XUiGridChange")


--==============================
 ---@desc 出战提示弹窗
--==============================
local XUiPanelChange = XClass(nil, "XUiPanelChange")

function XUiPanelChange:Ctor(ui, presetTeam)
    XTool.InitUiObjectByUi(self, ui)
    self.PresetTeam = presetTeam
    self.Grids = {}
end

function XUiPanelChange:Refresh()
    for i, pos in ipairs(TEAM_MEMBER_ORDER) do
        local grid = self.Grids[pos]
        if not grid then
            local ui = i == 1 and self.GridTeam or CS.UnityEngine.Object.Instantiate(self.GridTeam, self.PanelTeamContent, false)
            ui.name = string.format("GridTeam%d", pos)
            grid = XUiGridChange.New(ui)
            self.Grids[pos] = grid
        end
        grid:Refresh(pos, self.PresetTeam)
    end
end


--=========================================类分界线=========================================--


--==============================
 ---@desc 覆盖弹窗
--==============================
local XUiPanelReplace = XClass(nil, "XUiPanelReplace")

function XUiPanelReplace:Ctor(ui, trueTeam, presetTeam)
    XTool.InitUiObjectByUi(self, ui)
    self.TrueTeam = trueTeam
    self.PresetTeam = presetTeam
    self.Grids = {}
end

function XUiPanelReplace:Refresh()
    for i, pos in ipairs(TEAM_MEMBER_ORDER) do
        local grid = self.Grids[pos]
        if not grid then
            local ui = i == 1 and self.GridTeam or CS.UnityEngine.Object.Instantiate(self.GridTeam, self.PanelTeamContent, false)
            ui.name = string.format("GridTeam%d", pos)
            grid = XUiGridReplace.New(ui)
            self.Grids[pos] = grid
        end
        grid:Refresh(pos, self.TrueTeam, self.PresetTeam)
    end
end


--=========================================类分界线=========================================--


local XUiPartnerPresetPopup = XLuaUiManager.Register(XLuaUi, "UiPartnerPresetPopup")


function XUiPartnerPresetPopup:OnAwake()
    self:InitUi()
    self:InitCb()
end 

--==============================
 ---@trueTeam 真实的队伍  
 ---@presetTeam 预设的队伍  
--==============================
function XUiPartnerPresetPopup:OnStart(trueTeam, presetTeam, isCover, callback)
    self.TrueTeam = trueTeam
    self.PresetTeam = presetTeam
    self.IsCover = isCover
    self.CallBack = callback
    self.PanelReplace.gameObject:SetActiveEx(isCover)
    self.PanelPets.gameObject:SetActiveEx(not isCover)
    if isCover then
        self.PanelContent = XUiPanelReplace.New(self.PanelReplace, self.TrueTeam, self.PresetTeam)
    else
        self.PanelContent = XUiPanelChange.New(self.PanelPets, self.PresetTeam)
    end
    local title = XUiHelper.GetText("TipTitle")
    local content = isCover 
            and XUiHelper.GetText("PartnerTeamPrefabCoverTips") 
            or XUiHelper.GetText("PartnerTeamPrefabChooseTips")
    self.TxtTitle.text = title
    self.TxtTips.text = content

    self.PanelContent:Refresh()
end

function XUiPartnerPresetPopup:InitUi()
    
end

function XUiPartnerPresetPopup:InitCb()
    self.BtnConfirm.CallBack = function() 
        self:OnBtnConfirmClick()
    end

    self.BtnCancel.CallBack = function()
        self:Close()
    end

    self.BtnTanchuangClose.CallBack = function()
        self:Close()
    end
end

--region 回调事件

function XUiPartnerPresetPopup:OnBtnConfirmClick()
    self:Close()
    if self.CallBack then
        self.CallBack()
    end
end

--endregion

