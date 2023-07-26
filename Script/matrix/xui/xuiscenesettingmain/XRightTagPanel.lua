---场景设置切换界面右上角的信息面板
local XRightTagPanel=XClass(nil,'XRightTagPanel')
local modeTagPool={}

local XRightTagItem=require('XUi/XUiSceneSettingMain/XRightTagItem')

function XRightTagPanel:Ctor(ui,parent)
    XTool.InitUiObjectByUi(self,ui)
    self.Parent=parent
    self.tagTemplate=self.PanelLbItem.transform:Find('Function1')
    modeTagPool={}
end

function XRightTagPanel:RefreshData(template)
    --显示场景名称
    self.Text.text=template.Name
    --显示场景模式
    --XUiHelper.CreateTemplates(nil,modeTagPool,template.Tag,XRightTagItem.New,self.tagTemplate,self.PanelLbItem,XRightTagItem.SetContent)
    for index=1,#template.Tag do
        local item=self:GetTagItem(index)
        item.GameObject:SetActiveEx(true)
        item:SetContent(template.Tag[index])
    end

    for index=#template.Tag+1,#modeTagPool do
        local item=self:GetTagItem(index)
        item.GameObject:SetActiveEx(false)
    end
end

function XRightTagPanel:GetTagItem(index)
    if index>=1 and index<=#modeTagPool then
        return modeTagPool[index]
    else
        local ui=CS.UnityEngine.GameObject.Instantiate(self.tagTemplate,self.PanelLbItem.transform)
        modeTagPool[index]=XRightTagItem.New(ui)
        return modeTagPool[index]
    end
end

return XRightTagPanel