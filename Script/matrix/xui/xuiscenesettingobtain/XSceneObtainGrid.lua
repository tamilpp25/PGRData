local XSceneObtainGrid=XClass(nil,"XSceneObtainGrid")

function XSceneObtainGrid:Ctor(ui)
    XTool.InitUiObjectByUi(self,ui)
    XUiHelper.RegisterClickEvent(self, self.BtnClick, self.OnIconClick)
end

--@sceneId
function XSceneObtainGrid:Refresh(sceneId, template)
    if XTool.UObjIsNil(self.GameObject) then
        return
    end
    self.SceneId=sceneId
    self.GameObject:SetActiveEx(sceneId ~= nil)
    if not sceneId then
        return
    end

    -- 图标
    if self.RImgIcon then
        self.RImgIcon:SetRawImage(template.Icon)
        self.RImgIcon.gameObject:SetActiveEx(true)
    end
end

function XSceneObtainGrid:OnIconClick()
    --前往场景预览界面
    XDataCenter.PhotographManager.OpenScenePreview(self.SceneId)
end

return XSceneObtainGrid