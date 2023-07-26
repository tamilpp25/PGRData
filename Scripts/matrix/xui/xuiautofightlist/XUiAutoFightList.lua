local XUiAutoFightList = XLuaUiManager.Register(XLuaUi, "UiAutoFightList")
local XUiAutoFightRecord = require("XUi/XUiAutoFightList/XUiAutoFightRecord")

local tableinsert = table.insert
local tableremove = table.remove

local AnimBegin = "AniAutoFightListBegin"
local AnimEnd = "AniAutoFightListEnd"

function XUiAutoFightList:OnAwake()
    self:InitAutoScript()
    self:InitTemplate()
end

function XUiAutoFightList:OnStart()
    self:InitRecords()

    local beginCallback = function()
        XLuaUiManager.SetMask(true)
    end

    local finishCallBack = function()
        XLuaUiManager.SetMask(false)
    end

    self:PlayAnimation(AnimBegin, finishCallBack, beginCallback)
end

function XUiAutoFightList:OnEnable()
end

function XUiAutoFightList:OnDisable()
end

function XUiAutoFightList:OnDestroy()
end

function XUiAutoFightList:OnGetEvents()
    return nil
end

function XUiAutoFightList:OnNotify()
end

-- auto
-- Automatic generation of code, forbid to edit
function XUiAutoFightList:InitAutoScript()
    self:AutoInitUi()
    self:AutoAddListener()
end

function XUiAutoFightList:AutoInitUi()
    self.BtnClose = self.Transform:Find("SafeAreaContentPane/BtnClose"):GetComponent("Button")
end

function XUiAutoFightList:AutoAddListener()
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
end
-- auto
function XUiAutoFightList:OnBtnCloseClick()
    self.BtnClose.interactable = false

    for _, v in pairs(self.UiRecords) do
        v:OnDestroy()
    end

    local beginCallback = function()
        XLuaUiManager.SetMask(true)
    end

    local finishCallBack = function()
        XLuaUiManager.SetMask(false)
        self:Remove()
    end

    self:PlayAnimation(AnimEnd, finishCallBack, beginCallback)
end

function XUiAutoFightList:InitTemplate()
    self.Container = self.Transform:Find("SafeAreaContentPane/PanelAutoFight/ScrollView/Viewport/Content")
    self.Template = self.Transform:Find("SafeAreaContentPane/PanelAutoFight/ScrollView/Viewport/Content/AutoFightTemplate")
    self.Template.gameObject:SetActive(false)
end

function XUiAutoFightList:InitRecords()
    self.Records = XDataCenter.AutoFightManager.GetRecords()
    self.UiRecords = {}
    for index, record in pairs(self.Records) do
        self:NewRecord(index, record)
    end
end

function XUiAutoFightList:NewRecord(index, record)
    local transform = CS.UnityEngine.Object.Instantiate(self.Template, self.Container)
    local uiRecord = XUiAutoFightRecord.New(transform, self)
    uiRecord:SetData(index, record, function(idx)
            self:RemoveRecord(idx)
        end)
    tableinsert(self.UiRecords, uiRecord)
end

function XUiAutoFightList:RemoveRecord(index)
    local removeUiRecord = self.UiRecords[index]
    removeUiRecord:OnDestroy()
    CS.UnityEngine.Object.Destroy(removeUiRecord.GameObject)

    local max = #self.UiRecords - 1
    for i = index, max do
        self.UiRecords[i] = self.UiRecords[i + 1]
        self.UiRecords[i]:SetIndex(i)
    end
    tableremove(self.UiRecords, #self.UiRecords)

    if max == 0 then
        self:OnBtnCloseClick()
    end
end