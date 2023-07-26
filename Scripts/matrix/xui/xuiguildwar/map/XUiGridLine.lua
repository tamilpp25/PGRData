---@class XUiGridLine
local XUiGridLine = XClass(nil, "XUiGridLine")

function XUiGridLine:Ctor(ui, base)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.Base = base
    XTool.InitUiObject(self)
    self.StageName1 = self.Stage1.transform.name
    self.StageName2 = self.Stage2.transform.name
end
--开关路线显示
function XUiGridLine:SetLineActive(active)
    self.GameObject:SetActiveEx(active)
end
--无特殊情况路线显示
function XUiGridLine:SetLineNormal()
    self.Normal.gameObject:SetActiveEx(true)
    self.Press.gameObject:SetActiveEx(false)
end
--通关路线显示
function XUiGridLine:SetLineClear()
    self.Normal.gameObject:SetActiveEx(false)
    self.Press.gameObject:SetActiveEx(true)
end
--高光路线(会长指定的攻略路线)
function XUiGridLine:SetLineInPlan(isPlan)
    self.Select.gameObject:SetActiveEx(isPlan)
end

--更新关卡预览
function XUiGridLine:UpdateViewByStageNode(node1,node2)
    if node1 and node2 then
        self:SetLineActive(true)
        local IsClear = (node1:GetIsDead() or node1:GetIsBaseNode()) or (node2:GetIsDead() or node2:GetIsBaseNode())
        --如果是链接BOSS区域和近卫区的连线 则击破所有近卫区后才显示通关线
        if not IsClear or (node1:GetIsLastNode() and not node1:GetAllGuardIsDead())
                or (node2:GetIsLastNode() and not node2:GetAllGuardIsDead())  then
            self:SetLineNormal()
        else
            self:SetLineClear()
        end
    else
        self:SetLineActive(false)
    end
end

return XUiGridLine