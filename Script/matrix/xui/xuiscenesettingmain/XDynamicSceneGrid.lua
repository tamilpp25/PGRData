---场景动态列表中的元素控制器
local XDynamicSceneGrid=XClass(nil,"XDynamicSceneGrid")

function XDynamicSceneGrid:Ctor(ui,parent)
    self.Parent=parent
    XTool.InitUiObjectByUi(self,ui)
end

---更新元素的内容显示
function XDynamicSceneGrid:RefreshDisplay(sceneId,isHave)
    local template=XDataCenter.PhotographManager.GetSceneTemplateById(sceneId)
    
    self.Id=sceneId
    self.IsHave=isHave
    self.TxSceneName.text=template.Name
    self.ImgScene:SetRawImage(template.IconPath)
    --根据场景拥有情况显示
    if self.IsHave then
        self.Lock.gameObject:SetActiveEx(false)
        self.TxtLock.text=''
    else
        self.Lock.gameObject:SetActiveEx(true)
        self.TxtLock.text=template.LockDec
    end
    
    self:RefreshRedPoint()
end

---判断场景使用情况决定是否显示蓝点
function XDynamicSceneGrid:RefreshRedPoint()

    local state=XSaveTool.GetData(XDataCenter.PhotographManager.GetSceneStateKey(self.Id))

    if state==1 or state==2 or not self.IsHave then
        self.Red.gameObject:SetActiveEx(false)
    else
        self.Red.gameObject:SetActiveEx(true)
    end
end

function XDynamicSceneGrid:SetSelect(bool)
    self.Sel.gameObject:SetActiveEx(bool)
end

function XDynamicSceneGrid:SetUsedTag(bool)
    self.ImgUse.gameObject:SetActiveEx(bool)
end

return XDynamicSceneGrid