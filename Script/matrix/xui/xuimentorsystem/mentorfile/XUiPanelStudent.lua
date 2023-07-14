local XUiPanelStudent = XClass(nil, "XUiPanelStudent")
local XUiGridPlayer = require("XUi/XUiMentorSystem/MentorFile/XUiGridPlayer")
local Vector3 = CS.UnityEngine.Vector3
function XUiPanelStudent:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.StudentGridList = {}
    self.NodeList = {
        self.Node1,
        self.Node2,
        self.Node3,
        self.Node4,
        }
end

function XUiPanelStudent:UpdatePanel(data)
    self.Data = data
    if data and next(data) then
        self.StudentGridList = self.StudentGridList or {}
        for _,node in pairs(self.NodeList or {}) do
            node.gameObject:SetActiveEx(false)
        end
        for index,student in pairs(data or {}) do
            local node = self.NodeList[index]
            if node then
                node.gameObject:SetActiveEx(true)
                if not self.StudentGridList[index] then
                    local obj = CS.UnityEngine.Object.Instantiate(self.GridPlayer)
                    obj.transform:SetParent(node:GetObject("PanelPlayer"), false)
                    obj.transform.localPosition = Vector3(0, 0, 0)
                    obj.gameObject:SetActiveEx(true)
                    local grid = XUiGridPlayer.New(obj,false)
                    table.insert(self.StudentGridList, grid)
                end
                self.StudentGridList[index]:UpdateGrid(student)
            end
        end
    else
        self.GameObject:SetActiveEx(false)
    end
end

function XUiPanelStudent:SetParentNode(parent)
    self.Transform:SetParent(parent, false)
    self.Transform.localPosition = Vector3(0, 0, 0)
end

function XUiPanelStudent:GetParentNode(index)
    local node = self.NodeList[index]
    if node then
        return node:GetObject("PanelNext")
    end
    return nil
end

function XUiPanelStudent:GetMyIndex()
    for index,student in pairs(self.Data or {}) do
        if student.PlayerId == XPlayer.Id then
            return index
        end
    end
    return 0
end

return XUiPanelStudent