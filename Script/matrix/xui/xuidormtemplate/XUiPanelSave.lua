local XDynamicTableNormal = require("XUi/XUiCommon/XUiDynamicTable/XDynamicTableNormal")

local XUiPanelSave = XClass(nil, "XUiPanelSave")
local XUiGridTemplateSave = require("XUi/XUiDormTemplate/XUiGridTemplateSave")
local MaxNameLength = CS.XGame.Config:GetInt("DormReNameLen")

function XUiPanelSave:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi

    XTool.InitUiObject(self)
    self:AddListener()
    self:InitDynamicTable()
end

function XUiPanelSave:RegisterClickEvent(uiNode, func)
    if func == nil then
        XLog.Error("XUiPanelSave:RegisterClickEvent函数参数错误：参数func不能为空")
        return
    end

    if type(func) ~= "function" then
        XLog.Error("XUiPanelSave:RegisterClickEvent函数错误, 参数func需要是function类型, func的类型是" .. type(func))
    end

    local listener = function(...)
        func(self, ...)
    end

    CsXUiHelper.RegisterClickEvent(uiNode, listener)
end

function XUiPanelSave:AddListener()
    self:RegisterClickEvent(self.BtnAllClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnClose, self.OnBtnCloseClick)
    self:RegisterClickEvent(self.BtnSave, self.OnBtnSaveClick)
end

function XUiPanelSave:OnBtnCloseClick()
    self:Close()
end

function XUiPanelSave:OnBtnSaveClick()
    if not self.SelectGrid then
        XUiManager.TipError(CS.XTextManager.GetText("DormTemplateSaveNoneTip"))
        return
    end

    local editName = string.gsub(self.InFSigm.text, "^%s*(.-)%s*$", "%1")
    if string.len(editName) > 0 then
        local utf8Count = self.InFSigm.textComponent.cachedTextGenerator.characterCount - 1
        if utf8Count > MaxNameLength then
            XUiManager.TipError(CS.XTextManager.GetText("MaxNameLengthTips", MaxNameLength))
            return
        end
    else
        XUiManager.TipError(CS.XTextManager.GetText("DormTemplateSaveTipName"))
        return
    end

    local isCover = self.SelectGrid:CheckCoverSave()
    if isCover then       -- 覆盖存储
        local titletext = CS.XTextManager.GetText("TipTitle")
        local contenttext = CS.XTextManager.GetText("DormTemplateSaveTip")

        XUiManager.DialogTip(titletext, contenttext, XUiManager.DialogType.Normal, nil, function()
            self:DormCollectLayoutReq(isCover, editName)
        end)
        return
    end
    self:DormCollectLayoutReq(isCover, editName)
end

function XUiPanelSave:DormCollectLayoutReq(isCover, name)
    local id = isCover and self.SelectGrid.HomeRoomData:GetRoomId() or -1
    local homeFurnitrueDic = self.SceneHomeRoomData:GetFurnitureDic()
    local furnitrueList = {}

    for _, v in pairs(homeFurnitrueDic) do
        local data = {
            ConfigId = v.ConfigId,
            X = v.GridX,
            Y = v.GridY,
            Angle = v.RotateAngle,
        }
        table.insert(furnitrueList, data)
    end

    XDataCenter.DormManager.DormCollectLayoutReq(id, name, furnitrueList, function(roomId)
        self.IsSave = true
        -- 更换相机截屏
        local imgName = tostring(XPlayer.Id) .. tostring(roomId)
        local texture = XHomeSceneManager.CaptureCamera(imgName, false)
        XDataCenter.DormManager.SetLocalCaptureCache(imgName, texture)
        XUiManager.TipSuccess(CS.XTextManager.GetText("DormTemplateSaveSuccess"))
        self:Close()
    end)
end

function XUiPanelSave:OnGridClick(grid, name, isAutoClick, index)
    -- 取消选择
    if self.SelectGrid == grid and not isAutoClick then
        self.SelectGrid:SetSelect(false)
        self.SelectGrid = nil
        self.InFSigm.text = nil
        self.PageDatas[self.SelectIndex].IsDefaultSelect = false
        self.SelectIndex = 0
        return
    end

    if self.SelectGrid then
        self.SelectGrid:SetSelect(false)
    end

    grid:SetSelect(true)
    self.InFSigm.text = name
    if self.SelectIndex > 0 then
        self.PageDatas[self.SelectIndex].IsDefaultSelect = false
    end
    self.PageDatas[index].IsDefaultSelect = true
    self.SelectGrid = grid
    self.SelectIndex = index
end

function XUiPanelSave:Close()
    self.GameObject:SetActiveEx(false)
    if self.IsSave and self.SceneHomeRoomData and 
            self.SceneHomeRoomData:GetRoomDataType() == XDormConfig.DormDataType.Self then
        self.RootUi:OnBtnBackClick()
    end
end

function XUiPanelSave:Open(sceneHomeRoomData)
    self.PageDatas = {}
    self.SelectIndex = 1
    self.SceneHomeRoomData = sceneHomeRoomData

    local datas = XDataCenter.DormManager.GetTemplateDormitoryData(XDormConfig.DormDataType.Collect)
    local collectCfgs = XDormConfig.GetDormTemplateCollectList()
    local sceneHomeRoomId = sceneHomeRoomData:GetRoomId()
    local noRoonIndex = true

    for i = 1, #collectCfgs do
        local tempDate = {}
        if i > #datas then
            if i == #datas + 1 and noRoonIndex then
                self.SelectIndex = i
            end
            tempDate.HomeRoomData = nil
        else
            tempDate.HomeRoomData = datas[i]
            local dataRoomId = datas[i]:GetRoomId()
            if dataRoomId == sceneHomeRoomId then
                self.SelectIndex = i
                tempDate.IsDefaultSelect = true
                noRoonIndex = false
            end
        end

        tempDate.Index = i
        tempDate.CollectCfg = collectCfgs[i]
        table.insert(self.PageDatas, tempDate)
    end

    if noRoonIndex then
        self.PageDatas[self.SelectIndex].IsDefaultSelect = true
    end
    
    self.IsSave = false

    self.DynamicTable:SetDataSource(self.PageDatas)
    self.DynamicTable:ReloadDataSync(self.SelectIndex)
    self.GameObject:SetActiveEx(true)
end

function XUiPanelSave:InitDynamicTable()
    self.GridDormTemplate.gameObject:SetActiveEx(false)
    self.GameObject:SetActiveEx(false)
    self.DynamicTable = XDynamicTableNormal.New(self.PanelDynamicTable)
    self.DynamicTable:SetProxy(XUiGridTemplateSave)
    self.DynamicTable:SetDelegate(self)
end

-- 动态列表事件
function XUiPanelSave:OnDynamicTableEvent(event, index, grid)
    if event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_INIT then
        grid:Init(self)
    elseif event == DYNAMIC_DELEGATE_EVENT.DYNAMIC_GRID_ATINDEX then
        local d = self.PageDatas[index]
        grid:Refresh(d.HomeRoomData, d.CollectCfg, d.IsDefaultSelect, d.Index)
    end
end

return XUiPanelSave