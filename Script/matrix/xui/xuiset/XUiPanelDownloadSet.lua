local XUiPanelDownloadSet = XClass(nil, "XUiPanelDownloadSet")
local XUiSafeAreaAdapter = CS.XUiSafeAreaAdapter
local SetConfigs = XSetConfigs
local MaxOff
local XUiPanelDownloadSetItem = require("XUi/XUiSet/ChildItem/XUiPanelDownloadSetItem")

function XUiPanelDownloadSet:Ctor(ui, parent)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Parent = parent
    MaxOff = CS.XGame.ClientConfig:GetFloat("SpecialScreenOff")
    XTool.InitUiObject(self)
    self:InitUi()

    self.PanelNormal.gameObject:SetActiveEx(false)
    self.PanelSelect.gameObject:SetActiveEx(false)
end

function XUiPanelDownloadSet:InitUi()
    self.normalList = {}
    self.selectList = {}
    self.curIdx = 0
   
    self:AddListener()
end

function XUiPanelDownloadSet:AddListener()
end

function XUiPanelDownloadSet:OnDestroy()
    self.normalList = {}
    self.selectList = {}
    self.curIdx = 0
end


function XUiPanelDownloadSet:ShowPanel()
    self.GameObject:SetActive(true)
    self.IsShow = true

    self:SetupView()


    
    
end

function XUiPanelDownloadSet:OnClickItem(index)
    if self.curIdx == index then
        self.curIdx = 0
    else
        self.curIdx = index
    end
    
    self:SetupView()
end


function XUiPanelDownloadSet:SetupView()
    for k,v in pairs(self.normalList) do
        v.GameObject:SetActiveEx(false)
    end

    for k,v in pairs(self.selectList) do
        v.GameObject:SetActiveEx(false)
    end

    local normalIndex = 1
    local selectIndex = 1
    local index = 1
    --XLog.Debug("XDlcConfig:"..#(XDlcConfig.DlcDescConfig))
    for _, dlcItemData in ipairs(XDataCenter.DlcManager.GetAllItemList()) do
        --XLog.Debug("k:"..k)
        --XLog.Debug("v:"..v.Title)
        
        local isCurrent = index == self.curIdx
        if isCurrent then
            local selectItem = self:GetOneItem(selectIndex,self.selectList,self.PanelSelect)
            selectItem.Transform:SetSiblingIndex(index-1)
            selectItem.GameObject:SetActiveEx(true)
            selectItem:Setup(dlcItemData, index, isCurrent)

            selectIndex = selectIndex+1
        else
            local normalItem = self:GetOneItem(normalIndex,self.normalList,self.PanelNormal)
            normalItem.Transform:SetSiblingIndex(index-1)
            
            normalItem.GameObject:SetActiveEx(true)
            normalItem:Setup(dlcItemData, index, isCurrent)
            normalIndex = normalIndex+1
        end

        index = index + 1
    end
end



function XUiPanelDownloadSet:GetOneItem(index,list,itemClone)
    if list[index] == nil then
        local go =  CS.UnityEngine.Object.Instantiate(itemClone)
        go.transform:SetParent(self.PanelContent,false)
        local item = XUiPanelDownloadSetItem.New(go,self)
        list[index] = item
    end
    return list[index]
end

function XUiPanelDownloadSet:HidePanel()
    self.IsShow = false
    self.GameObject:SetActive(false)
end

function XUiPanelDownloadSet:CheckDataIsChange()
    return false
end

function XUiPanelDownloadSet:SaveChange()
    -- body
end

function XUiPanelDownloadSet:CancelChange()
    -- body
end

return XUiPanelDownloadSet