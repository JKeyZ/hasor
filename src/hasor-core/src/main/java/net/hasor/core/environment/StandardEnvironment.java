/*
 * Copyright 2008-2009 the original ������(zyc@hasor.net).
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package net.hasor.core.environment;
import java.io.File;
import java.io.IOException;
import java.net.URI;
import java.net.URISyntaxException;
import java.net.URL;
import net.hasor.core.Environment;
import net.hasor.core.Settings;
import net.hasor.core.setting.StandardContextSettings;
import org.more.util.ResourcesUtils;
/**
 * {@link Environment}�ӿ�ʵ���ࡣ
 * @version : 2013-9-11
 * @author ������(zyc@hasor.net)
 */
public class StandardEnvironment extends AbstractEnvironment {
    public StandardEnvironment() {
        this((URI) null);
    }
    public StandardEnvironment(String mainSettings) throws IOException, URISyntaxException {
        URL resURL = ResourcesUtils.getResource(mainSettings);
        if (resURL == null)
            return;
        this.settingURI = resURL.toURI();
        this.initEnvironment();
    }
    public StandardEnvironment(File mainSettings) {
        this((mainSettings == null) ? null : mainSettings.toURI());
    }
    public StandardEnvironment(URI mainSettings) {
        if (mainSettings != null)
            this.settingURI = mainSettings;
        this.initEnvironment();
    }
    //---------------------------------------------------------------------------------Basic Method
    protected URI settingURI = null;
    public URI getSettingURI() {
        return this.settingURI;
    }
    protected Settings createSettings() throws IOException {
        StandardContextSettings settings = null;
        if (this.settingURI == null) {
            settings = new StandardContextSettings();
            this.settingURI = settings.getSettingURI();
        } else
            settings = new StandardContextSettings(this.settingURI);
        return settings;
    }
}