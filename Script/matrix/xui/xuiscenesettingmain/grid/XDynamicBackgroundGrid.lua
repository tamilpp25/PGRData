---场景动态列表中的元素控制器
local XDynamicBackgroundGrid = XClass(XUiNode,"XDynamicBackgroundGrid")

---更新元素的内容显示
function XDynamicBackgroundGrid:RefreshDisplay(backgroundId)
    local template = XDataCenter.PhotographManager.GetSceneTemplateById(backgroundId)
    
    self.Id = backgroundId
    self.TxSceneName.text = template.Name
    self.ImgScene:SetRawImage(template.IconPath)
    --根据场景拥有情况显示
    local isHave = XDataCenter.PhotographManager.CheckSceneIsHaveById(backgroundId)
    if isHave then
        self.Lock.gameObject:SetActiveEx(false)
        self.TxtLock.text = ''
    else
        self.Lock.gameObject:SetActiveEx(true)
        self.TxtLock.text = template.LockDec
    end

    -- 使用中
    if self.TagUse then
        local curShowSceneId = XDataCenter.PhotographManager.GetCurSceneId()
        self.TagUse.gameObject:SetActiveEx(backgroundId == curShowSceneId)
    end

    -- 随机中
    if self.TagRandom then
        local isRandom = XDataCenter.PhotographManager.GetRandomBackgroundDataInRandomPoolById(backgroundId)
        self.TagRandom.gameObject:SetActiveEx(isRandom and XDataCenter.PhotographManager.GetIsRandomBackground())
    end
    
    self:RefreshRedPoint()
end

---判断场景使用情况决定是否显示蓝点
function XDynamicBackgroundGrid:RefreshRedPoint()
    if not self.Id then
        return
    end

    local sceneCount = XDataCenter.PhotographManager.GetOwnSceneCount()
    -- 如果只有一个默认场景 则不需要蓝点
    if sceneCount == 1 then
        self.Red.gameObject:SetActiveEx(false)
        return
    end

    local checkData = XDataCenter.PhotographManager.CheckSceneIsNewInTempData(self.Id)
    local isHave = XDataCenter.PhotographManager.CheckSceneIsHaveById(self.Id)
    if isHave and checkData then
        self.Red.gameObject:SetActiveEx(true)
    else
        self.Red.gameObject:SetActiveEx(false)
    end
end

function XDynamicBackgroundGrid:SetSelect(bool)
    self.Sel.gameObject:SetActiveEx(bool)
end

return XDynamicBackgroundGrid