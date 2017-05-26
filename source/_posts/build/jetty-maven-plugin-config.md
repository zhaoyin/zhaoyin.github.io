
---
title: jetty maven plugin config
date: 2017-05-26 22:40:56
categories:
    - build
tags: 
    - jetty
    - maven
    - config
---

URL：[http/https]://hostname:port/contextPath/servletPath/pathInfo

如果没有contextPath，则默认使用root上下文，root上下文的路径为"/"。

warName.war
在没有XML IoC文件的情况下：

* 如果WAR文件名是myapp.war，那么上下文路径是：/myapp；
* 如果WAR文件名是ROOT.war，那么上下文路径是：/；
* 如果WAR文件名是ROOT-foobar.war，那么上下文路径是/，虚拟host是foobar。

注意这个contextPath，在下面的设置中设置了url路径会发生变化。

[jetty-maven-plugin-config](http://www.eclipse.org/jetty/documentation/current/jetty-maven-plugin.html)

仅作记录，查字典用。此文从上述网址复制而来。

The Jetty Maven plugin is useful for rapid development and testing. You can add it to any webapp project that is structured according to the Maven defaults. The plugin can then periodically scan your project for changes and automatically redeploy the webapp if any are found. This makes the development cycle more productive by eliminating the build and deploy steps: you use your IDE to make changes to the project, and the running web container automatically picks them up, allowing you to test them straight away.

**You should use Maven 3.3+ for this plugin.**

While the Jetty Maven Plugin can be very useful for development we do not recommend its use in a production capacity. In order for the plugin to work it needs to leverage many internal Maven apis and Maven itself it not a production deployment tool. We recommend either the traditional distribution deployment approach or using embedded Jetty.

## Quick Start: Get Up and Running

First, add jetty-maven-plugin to your pom.xml definition:
```
<plugin>
  <groupId>org.eclipse.jetty</groupId>
  <artifactId>jetty-maven-plugin</artifactId>
  <version>9.4.5.v20170502</version>
</plugin>
```
Then, from the same directory as your root pom.xml, type:

> mvn jetty:run

This starts Jetty and serves up your project on http://localhost:8080/.

Jetty will continue to run until you stop it. While it runs it periodically scans for changes to your project files If you save changes and recompile your class files, Jetty redeploys your webapp, and you can instantly test the changes that were just made.

You can terminate the plugin with a ctrl-c in the terminal window where it is running.

 Note
The classpath of the running Jetty instance and its deployed webapp are managed by Maven, and may not be exactly what you expect. For example: a webapp’s dependent jars might be referenced via the local repository, not the WEB-INF/lib directory.

## Supported Goals

The Jetty Maven plugin has a number of distinct Maven goals. Arguably the most useful is the run goal which runs Jetty on an unassembled webapp. There are other goals which help you accomplish different tasks. For example, you might need to run your webapp in a forked instance of Jetty rather than within the process running Maven; or you may need finer grained control over the maven lifecycle stage in which you wish to deploy your webapp. There are different goals to accomplish these tasks, as well as several others.

To see a list of all goals supported by the Jetty Maven plugin, do:

> mvn jetty:help
To see the detailed list of parameters that can be configured for a particular goal, in addition to its description, do:

> mvn jetty:help -Ddetail=true -Dgoal= <goal name>

## Configuring the Jetty Container

These configuration elements set up the Jetty environment in which your webapp executes. They are common to most goals:

### httpConnector
Optional. If not specified, Jetty will create a ServerConnector instance listening on port 8080. You can change this default port number by using the system property jetty.http.port on the command line, for example, mvn -Djetty.http.port=9999 jetty:run. Alternatively, you can use this configuration element to set up the information for the ServerConnector. The following are the valid configuration sub-elements:

#### port
The port number for the connector to listen on. By default it is 8080.
#### host
The particular interface for the connector to listen on. By default, all interfaces.
#### name
The name of the connector, which is useful for configuring contexts to respond only on particular connectors.
#### idleTimeout
Maximum idle time for a connection.
#### soLinger
The socket linger time.

You could instead configure the connectors in a standard jetty xml config file and put its location into the ` jettyXml` parameter. Note that since jetty-9.0 it is no longer possible to configure a https connector directly in the pom.xml: you need to use jetty xml config files to do it.

### jettyXml
Optional. A comma separated list of locations of jetty xml files to apply in addition to any plugin configuration parameters. You might use it if you have other webapps, handlers, specific types of connectors etc., to deploy, or if you have other Jetty objects that you cannot configure from the plugin.
### scanIntervalSeconds
The pause in seconds between sweeps of the webapp to check for changes and automatically hot redeploy if any are detected. By default this is 0, which disables hot deployment scanning. A number greater than 0 enables it.
### reload
Default value is "automatic", used in conjunction with a non-zero `scanIntervalSeconds` causes automatic hot redeploy when changes are detected. Set to "manual" instead to trigger scanning by typing a linefeed in the console running the plugin. This might be useful when you are doing a series of changes that you want to ignore until you’re done. In that use, use the reload parameter.
### dumpOnStart
Optional. Default value is false. If true, then jetty will dump out the server structure on start.
### loginServices
Optional. A list of org.eclipse.jetty.security.LoginService implementations. Note that there is no default realm. If you use a realm in your web.xml you can specify a corresponding realm here. You could instead configure the login services in a jetty xml file and add its location to the jettyXml parameter.
### requestLog
Optional. An implementation of the org.eclipse.jetty.server.RequestLog request log interface. An implementation that respects the NCSA format is available as org.eclipse.jetty.server.NCSARequestLog. There are three other ways to configure the RequestLog:

In a jetty xml config file, as specified in the jettyXml parameter.
In a context xml config file, as specified in the contextXml parameter.
In the webApp element.
See Configuring Request Logs for more information.

### server
Optional as of Jetty 9.3.1. This would configure an instance of the org.eclipse.jetty.server.Server for the plugin to use, however it is usually NOT necessary to configure this, as the plugin will automatically configure one for you. In particular, if you use the jettyXml element, then you generally DON’T want to define this element, as you are probably using the jettyXml file to configure up a Server with a special constructor argument, such as a custom threadpool. If you define both a server element AND use a jetty xml element which points to a config file that has a line like <Configure id="Server" class="org.eclipse.jetty.server.Server"> then the the xml configuration will override what you configure for the server in the pom.xml.
### stopPort
Optional. Port to listen on for stop commands. Useful to use in conjunction with the stop or run-forked goals.
### stopKey
Optional. Used in conjunction with stopPort for stopping jetty. Useful when used in conjunction with the stop or run-forked goals.
### systemProperties
Optional. Allows you to configure System properties for the execution of the plugin. For more information, see Setting System Properties.
### systemPropertiesFile
Optional. A file containing System properties to set for the execution of the plugin. By default, settings that you make here do not override any system properties already set on the command line, by the JVM, or in the POM via systemProperties. Read Setting System Properties for how to force overrides.
### skip
Default is false. If true, the execution of the plugin exits. Same as setting the SystemProperty -Djetty.skip on the command line. This is most useful when configuring Jetty for execution during integration testing and you want to skip the tests.
### useProvidedScope
Default value is false. If true, the dependencies with <scope>provided</scope> are placed onto the container classpath. Be aware that this is NOT the webapp classpath, as "provided" indicates that these dependencies would normally be expected to be provided by the container. You should very rarely ever need to use this. Instead, you should copy the provided dependencies as explicit dependencies of the plugin instead.
### excludedGoals
Optional. A list of Jetty plugin goal names that will cause the plugin to print an informative message and exit. Useful if you want to prevent users from executing goals that you know cannot work with your project.

## Configuring a Https Connector

In order to configure an HTTPS connector, you need to use jetty xml configuration files. This example uses files copied directly from the jetty distribution etc/ directory, although you can of course make up your own xml file or files. We will use the following files:

### jetty.xml
Sets up various characteristics of the org.eclipse.jetty.server.Server instance for the plugin to use. Importantly, it sets up the org.eclipse.jetty.server.HttpConfiguration element that we can refer to in subsequent xml files that configure the connectors. Here’s the relevant section:
```
    <New id="httpConfig" class="org.eclipse.jetty.server.HttpConfiguration">
      <Set name="secureScheme">https</Set>
      <Set name="securePort"><Property name="jetty.secure.port" default="8443" /></Set>
      <Set name="outputBufferSize">32768</Set>
      <Set name="requestHeaderSize">8192</Set>
      <Set name="responseHeaderSize">8192</Set>
      <Set name="sendServerVersion">true</Set>
      <Set name="sendDateHeader">false</Set>
      <Set name="headerCacheSize">512</Set>

      <!-- Uncomment to enable handling of X-Forwarded- style headers
      <Call name="addCustomizer">
        <Arg><New class="org.eclipse.jetty.server.ForwardedRequestCustomizer"/></Arg>
      </Call>
      -->
    </New>
```

### jetty-ssl.xml
Set up ssl which will be used by the https connector. Here’s the jetty-ssl.xml file from the jetty-distribution:
```
<?xml version="1.0"?>
<!DOCTYPE Configure PUBLIC "-//Jetty//Configure//EN" "http://www.eclipse.org/jetty/configure_9_3.dtd">

<!-- ============================================================= -->
<!-- Base SSL configuration                                        -->
<!-- This configuration needs to be used together with 1 or more   -->
<!-- of jetty-https.xml or jetty-http2.xml                         -->
<!-- ============================================================= -->
<Configure id="Server" class="org.eclipse.jetty.server.Server">

  <!-- =========================================================== -->
  <!-- Add a SSL Connector with no protocol factories              -->
  <!-- =========================================================== -->
  <Call  name="addConnector">
    <Arg>
      <New id="sslConnector" class="org.eclipse.jetty.server.ServerConnector">
        <Arg name="server"><Ref refid="Server" /></Arg>
        <Arg name="acceptors" type="int"><Property name="jetty.ssl.acceptors" deprecated="ssl.acceptors" default="-1"/></Arg>
        <Arg name="selectors" type="int"><Property name="jetty.ssl.selectors" deprecated="ssl.selectors" default="-1"/></Arg>
        <Arg name="factories">
          <Array type="org.eclipse.jetty.server.ConnectionFactory">
            <!-- uncomment to support proxy protocol
            <Item>
              <New class="org.eclipse.jetty.server.ProxyConnectionFactory"/>
            </Item>-->
          </Array>
        </Arg>

        <Set name="host"><Property name="jetty.ssl.host" deprecated="jetty.host" /></Set>
        <Set name="port"><Property name="jetty.ssl.port" deprecated="ssl.port" default="8443" /></Set>
        <Set name="idleTimeout"><Property name="jetty.ssl.idleTimeout" deprecated="ssl.timeout" default="30000"/></Set>
        <Set name="soLingerTime"><Property name="jetty.ssl.soLingerTime" deprecated="ssl.soLingerTime" default="-1"/></Set>
        <Set name="acceptorPriorityDelta"><Property name="jetty.ssl.acceptorPriorityDelta" deprecated="ssl.acceptorPriorityDelta" default="0"/></Set>
        <Set name="acceptQueueSize"><Property name="jetty.ssl.acceptQueueSize" deprecated="ssl.acceptQueueSize" default="0"/></Set>
      </New>
    </Arg>
  </Call>

  <!-- =========================================================== -->
  <!-- Create a TLS specific HttpConfiguration based on the        -->
  <!-- common HttpConfiguration defined in jetty.xml               -->
  <!-- Add a SecureRequestCustomizer to extract certificate and    -->
  <!-- session information                                         -->
  <!-- =========================================================== -->
  <New id="sslHttpConfig" class="org.eclipse.jetty.server.HttpConfiguration">
    <Arg><Ref refid="httpConfig"/></Arg>
    <Call name="addCustomizer">
      <Arg>
        <New class="org.eclipse.jetty.server.SecureRequestCustomizer">
          <Arg name="sniHostCheck" type="boolean"><Property name="jetty.ssl.sniHostCheck" default="true"/></Arg>
          <Arg name="stsMaxAgeSeconds" type="int"><Property name="jetty.ssl.stsMaxAgeSeconds" default="-1"/></Arg>
          <Arg name="stsIncludeSubdomains" type="boolean"><Property name="jetty.ssl.stsIncludeSubdomains" default="false"/></Arg>
        </New>
      </Arg>
    </Call>
  </New>

</Configure>
```

### jetty-https.xml
Set up the https connector using the HttpConfiguration from jetty.xml and the ssl configuration from jetty-ssl.xml:
```
<?xml version="1.0"?>
<!DOCTYPE Configure PUBLIC "-//Jetty//Configure//EN" "http://www.eclipse.org/jetty/configure_9_3.dtd">

<!-- ============================================================= -->
<!-- Configure a HTTPS connector.                                  -->
<!-- This configuration must be used in conjunction with jetty.xml -->
<!-- and jetty-ssl.xml.                                            -->
<!-- ============================================================= -->
<Configure id="sslConnector" class="org.eclipse.jetty.server.ServerConnector">

  <Call name="addIfAbsentConnectionFactory">
    <Arg>
      <New class="org.eclipse.jetty.server.SslConnectionFactory">
        <Arg name="next">http/1.1</Arg>
        <Arg name="sslContextFactory"><Ref refid="sslContextFactory"/></Arg>
      </New>
    </Arg>
  </Call>

  <Call name="addConnectionFactory">
    <Arg>
      <New class="org.eclipse.jetty.server.HttpConnectionFactory">
        <Arg name="config"><Ref refid="sslHttpConfig" /></Arg>
        <Arg name="compliance"><Call class="org.eclipse.jetty.http.HttpCompliance" name="valueOf"><Arg><Property name="jetty.http.compliance" default="RFC7230"/></Arg></Call></Arg>
      </New>
    </Arg>
  </Call>

</Configure>
```
Now you need to let the plugin know to apply the files above:
```
<plugin>
  <groupId>org.eclipse.jetty</groupId>
  <artifactId>jetty-maven-plugin</artifactId>
  <version>9.4.5.v20170502</version>
  <configuration>
    <jettyXml>jetty.xml,jetty-ssl.xml,jetty-https.xml</jettyXml>
  </configuration>
</plugin>
```

> Just like with an installed distribution of Jetty, the ordering of the xml files is significant.

You can also use Jetty xml files to configure a http connector for the plugin to use. Here we use the same jetty-http.xml file from the Jetty distribution:
```
<?xml version="1.0"?>
<!DOCTYPE Configure PUBLIC "-//Jetty//Configure//EN" "http://www.eclipse.org/jetty/configure_9_3.dtd">

<!-- ============================================================= -->
<!-- Configure the Jetty Server instance with an ID "Server"       -->
<!-- by adding a HTTP connector.                                   -->
<!-- This configuration must be used in conjunction with jetty.xml -->
<!-- ============================================================= -->
<Configure id="Server" class="org.eclipse.jetty.server.Server">

  <!-- =========================================================== -->
  <!-- Add a HTTP Connector.                                       -->
  <!-- Configure an o.e.j.server.ServerConnector with a single     -->
  <!-- HttpConnectionFactory instance using the common httpConfig  -->
  <!-- instance defined in jetty.xml                               -->
  <!--                                                             -->
  <!-- Consult the javadoc of o.e.j.server.ServerConnector and     -->
  <!-- o.e.j.server.HttpConnectionFactory for all configuration    -->
  <!-- that may be set here.                                       -->
  <!-- =========================================================== -->
  <Call name="addConnector">
    <Arg>
      <New id="httpConnector" class="org.eclipse.jetty.server.ServerConnector">
        <Arg name="server"><Ref refid="Server" /></Arg>
        <Arg name="acceptors" type="int"><Property name="jetty.http.acceptors" deprecated="http.acceptors" default="-1"/></Arg>
        <Arg name="selectors" type="int"><Property name="jetty.http.selectors" deprecated="http.selectors" default="-1"/></Arg>
        <Arg name="factories">
          <Array type="org.eclipse.jetty.server.ConnectionFactory">
            <Item>
              <New class="org.eclipse.jetty.server.HttpConnectionFactory">
                <Arg name="config"><Ref refid="httpConfig" /></Arg>
                <Arg name="compliance"><Call class="org.eclipse.jetty.http.HttpCompliance" name="valueOf"><Arg><Property name="jetty.http.compliance" default="RFC7230"/></Arg></Call></Arg>
              </New>
            </Item>
          </Array>
        </Arg>
        <Set name="host"><Property name="jetty.http.host" deprecated="jetty.host" /></Set>
        <Set name="port"><Property name="jetty.http.port" deprecated="jetty.port" default="8080" /></Set>
        <Set name="idleTimeout"><Property name="jetty.http.idleTimeout" deprecated="http.timeout" default="30000"/></Set>
        <Set name="soLingerTime"><Property name="jetty.http.soLingerTime" deprecated="http.soLingerTime" default="-1"/></Set>
        <Set name="acceptorPriorityDelta"><Property name="jetty.http.acceptorPriorityDelta" deprecated="http.acceptorPriorityDelta" default="0"/></Set>
        <Set name="acceptQueueSize"><Property name="jetty.http.acceptQueueSize" deprecated="http.acceptQueueSize" default="0"/></Set>
      </New>
    </Arg>
  </Call>

</Configure>
```
Now we add it to the list of configs for the plugin to apply:
```
<plugin>
  <groupId>org.eclipse.jetty</groupId>
  <artifactId>jetty-maven-plugin</artifactId>
  <version>9.4.5.v20170502</version>
  <configuration>
    <jettyXml>jetty.xml,jetty-http.xml,jetty-ssl.xml,jetty-https.xml</jettyXml>
  </configuration>
</plugin>
```
Alternatively, you can use the httpConnector configuration element inside the pom instead as described above.

## Configuring Your WebApp

These configuration parameters apply to your webapp. They are common to almost all goals.

### webApp
This is an instance of org.eclipse.jetty.maven.plugin.JettyWebAppContext, which is an extension to the class org.eclipse.jetty.webapp.WebAppContext. You can use any of the setter methods on this object to configure your webapp. Here are a few of the most useful ones:

#### contextPath
The context path for your webapp. By default, this is set to /. If using a custom value for this parameter, you probably want to include the leading /, example /mycontext.
#### descriptor
The path to the web.xml file for your webapp.
#### defaultsDescriptor
The path to a webdefault.xml file that will be applied to your webapp before the web.xml. If you don’t supply one, Jetty uses a default file baked into the jetty-webapp.jar.
#### overrideDescriptor
The path to a web.xml file that Jetty applies after reading your web.xml. You can use this to replace or add configuration.
#### tempDirectory
The path to a dir that Jetty can use to expand or copy jars and jsp compiles when your webapp is running. The default is ${project.build.outputDirectory}/tmp.
#### baseResource
The path from which Jetty serves static resources. Defaults to src/main/webapp.
#### resourceBases
Use instead of baseResource if you have multiple directories from which you want to serve static content. This is an array of directory names.
#### baseAppFirst
Defaults to "true". Controls whether any overlaid wars are added before or after the original base resource(s) of the webapp. See the section on overlaid wars for more information.
#### containerIncludeJarPattern
Defaults to .*/javax.servlet-[^/]*\.jar$|.*/servlet-api-[^/]*\.jar$|.*javax.servlet.jsp.jstl-[^/]*\.jar|.*taglibs-standard-impl-.*\.jar. This is a pattern that is applied to the names of the jars on the container’s classpath (ie the classpath of the plugin, not that of the webapp) that should be scanned for fragments, tlds, annotations etc. This is analogous to the context attribute org.eclipse.jetty.server.webapp.ContainerIncludeJarPattern that is documented here. You can define extra patterns of jars that will be included in the scan.
#### webInfIncludeJarPattern
Defaults to matching all of the dependency jars for the webapp (ie the equivalent of WEB-INF/lib). You can make this pattern more restrictive to only match certain jars by using this setter. This is analogous to the context attribute org.eclipse.jetty.server.webapp.WebInfIncludeJarPattern that is documented here.
### contextXml
The path to a context xml file that is applied to your webapp AFTER the webApp element.

## jetty:run

The run goal runs on a webapp that does not have to be built into a WAR. Instead, Jetty deploys the webapp from its sources. It looks for the constituent parts of a webapp in the Maven default project locations, although you can override these in the plugin configuration. For example, by default it looks for:

* resources in ${project.basedir}/src/main/webapp
* classes in ${project.build.outputDirectory}
* web.xml in ${project.basedir}/src/main/webapp/WEB-INF/
The plugin automatically ensures the classes are rebuilt and up-to-date before deployment. If you change the source of a class and your IDE automatically compiles it in the background, the plugin picks up the changed class.

You do not need to assemble the webapp into a WAR, saving time during the development cycle. Once invoked, you can configure the plugin to run continuously, scanning for changes in the project and automatically performing a hot redeploy when necessary. Any changes you make are immediately reflected in the running instance of Jetty, letting you quickly jump from coding to testing, rather than going through the cycle of: code, compile, reassemble, redeploy, test.

Here is an example, which turns on scanning for changes every ten seconds, and sets the webapp context path to /test:
```
<plugin>
  <groupId>org.eclipse.jetty</groupId>
  <artifactId>jetty-maven-plugin</artifactId>
  <version>9.4.5.v20170502</version>
  <configuration>
    <scanIntervalSeconds>10</scanIntervalSeconds>
    <webApp>
      <contextPath>/test</contextPath>
    </webApp>
  </configuration>
</plugin>
```
### Configuration

In addition to the webApp element that is common to most goals, the jetty:run goal supports:

#### classesDirectory
Location of your compiled classes for the webapp. You should rarely need to set this parameter. Instead, you should set build outputDirectory in your pom.xml.
#### testClassesDirectory
Location of the compiled test classes for your webapp. By default this is ${project.build.testOutputDirectory}.
#### useTestScope
If true, the classes from testClassesDirectory and dependencies of scope "test" are placed first on the classpath. By default this is false.
#### webAppSourceDirectory
By default, this is set to ${project.basedir}/src/main/webapp. If your static sources are in a different location, set this parameter accordingly.
#### jettyEnvXml
Optional. Location of a jetty-env.xml file, which allows you to make JNDI bindings that satisfy env-entry, resource-env-ref, and resource-ref linkages in the web.xml that are scoped only to the webapp and not shared with other webapps that you might be deploying at the same time (for example, by using a ` jettyConfig` file).
#### scanTargets
Optional. A list of files and directories to periodically scan in addition to those the plugin automatically scans.
#### scanTargetPatterns
Optional. If you have a long list of extra files you want scanned, it is more convenient to use pattern matching expressions to specify them instead of enumerating them with the scanTargetsList of scanTargetPatterns, each consisting of a directory, and including and/or excluding parameters to specify the file matching patterns.
#### scanClassesPattern
Since 9.3.0. Optional. Include and exclude patterns that can be applied to the classesDirectory for the purposes of scanning, it does not affect the classpath. If a file or directory is excluded by the patterns then a change in that file (or subtree in the case of a directory) is ignored and will not cause the webapp to redeploy. Patterns are specified as a relative path using a glob-like syntax as described in the javadoc for FileSystem.getPathMatcher.
#### scanTestClassesPattern
Since 9.3.0. Optional. Include and exclude patterns that can be applied to the testClassesDirectory for the purposes of scanning, it does not affect the classpath. If a file or directory is excluded by the patterns then a change in that file (or subtree in the case of a directory) is ignored and will not cause the webapp to redeploy. Patterns are specified as a relative path using a glob-like syntax as described in the javadoc for FileSystem.getPathMatcher.
Here’s an example:
```
<project>
...
  <plugins>
...
    <plugin>
      <groupId>org.eclipse.jetty</groupId>
      <artifactId>jetty-maven-plugin</artifactId>
      <version>9.4.5.v20170502</version>
      <configuration>
        <webAppSourceDirectory>${project.basedir}/src/staticfiles</webAppSourceDirectory>
        <webApp>
          <contextPath>/</contextPath>
          <descriptor>${project.basedir}/src/over/here/web.xml</descriptor>
          <jettyEnvXml>${project.basedir}/src/over/here/jetty-env.xml</jettyEnvXml>
        </webApp>
        <classesDirectory>${project.basedir}/somewhere/else</classesDirectory>
        <scanClassesPattern>
          <excludes>
             <exclude>**/Foo.class</exclude>
          </excludes>
        </scanClassesPattern>
        <scanTargets>
          <scanTarget>src/mydir</scanTarget>
          <scanTarget>src/myfile.txt</scanTarget>
        </scanTargets>
        <scanTargetPatterns>
          <scanTargetPattern>
            <directory>src/other-resources</directory>
            <includes>
              <include>**/*.xml</include>
              <include>**/*.properties</include>
            </includes>
            <excludes>
              <exclude>**/myspecial.xml</exclude>
              <exclude>**/myspecial.properties</exclude>
            </excludes>
          </scanTargetPattern>
        </scanTargetPatterns>
      </configuration>
    </plugin>
  </plugins>
</project>
```
If, for whatever reason, you cannot run on an unassembled webapp, the goals run-war and run-exploded work on unassembled webapps.

## jetty:run-war

This goal first packages your webapp as a WAR file and then deploys it to Jetty. If you set a non-zero scanInterval, Jetty watches your pom.xml and the WAR file; if either changes, it redeploys the war.

### Configuration

#### war
The location of the built WAR file. This defaults to ${project.build.directory}/${project.build.finalName}.war. If this is not sufficient, set it to your custom location.
Here’s how to set it:
```
<project>
...
  <plugins>
...
    <plugin>
      <groupId>org.eclipse.jetty</groupId>
      <artifactId>jetty-maven-plugin</artifactId>
      <version>9.4.5.v20170502</version>
      <configuration>
        <war>${project.basedir}/target/mycustom.war</war>
      </configuration>
    </plugin>
  </plugins>
</project>
```
## jetty:run-exploded

The run-exploded goal first assembles your webapp into an exploded WAR file and then deploys it to Jetty. If you set a non-zero scanInterval, Jetty watches your pom.xml,`WEB-INF/lib, WEB-INF/ and WEB-INF/web.xml for changes and redeploys when necessary.

### Configuration

#### war
The location of the exploded WAR. This defaults to ${project.build.directory}/${project.build.finalName}, but you can override the default by setting this parameter.
Here’s how to set it:
```
<project>
...
  <plugins>
...
    <plugin>
      <groupId>org.eclipse.jetty</groupId>
      <artifactId>maven-jetty-plugin</artifactId>
      <version>9.4.5.v20170502</version>
      <configuration>
        <war>${project.basedir}/target/myfunkywebapp</war>
      </configuration>
    </plugin>
  </plugins>
</project>
```
## jetty:deploy-war

This is basically the same as jetty:run-war, but without assembling the WAR of the current module - you can nominate the location of any war to run. Unlike run-war, the phase in which this plugin executes is not bound to the "package" phase - you may bind it to any phase to use it.

### Configuration

#### war
The location of the WAR file. This defaults to ${project.build.directory}/${project.build.finalName}, but you can override the default by setting this parameter.
#### daemon
If true, this plugin will start Jetty but let the build continue. This is useful if you want to start jetty as an execution binding in a particular phase and then stop it in another. Alternatively, you can set this parameter to false, in which case Jetty will block and you will need to use a ctrl-c to stop it.
Here’s the configuration:
```
<project>
...
  <plugins>
...
  <plugin>
    <groupId>org.eclipse.jetty</groupId>
    <artifactId>jetty-maven-plugin</artifactId>
    <version>9.4.5.v20170502</version>
    <configuration>
      <war>/opt/special/some-app.war</war>
      <stopKey>alpha</stopKey>
      <stopPort>9099</stopPort>
    </configuration>
    <executions>
      <execution>
        <id>start-jetty</id>
        <phase>test-compile</phase>
        <goals>
          <goal>deploy-war</goal>
        </goals>
      </execution>
      <execution>
        <id>stop-jetty</id>
        <phase>test</phase>
        <goals>
          <goal>stop</goal>
        </goals>
      </execution>
     </executions>
    </plugin>
  </plugins>
</project>
```
## jetty:run-forked

This goal allows you to start the webapp in a new JVM, optionally passing arguments to that new JVM. This goal supports the same configuration parameters as the jetty:run goal with a couple of extras to help configure the forked process.

### Configuration

The available configuration parameters - in addition to those for the jetty:run goal - are:

#### jvmArgs
Optional. A string representing arbitrary arguments to pass to the forked JVM.
#### waitForChild
Default is true. This causes the parent process to wait for the forked process to exit. In this case you can use ctrl-c to terminate both processes. It is more useful to set it to false, in which case the parent process terminates whilst leaving the child process running. You use the jetty:stop goal to stop the child process.
#### maxStartupLines
Default is 50. This is maximum number of lines the parent process reads from the child process to receive an indication that the child has started. If the child process produces an excessive amount of output on stdout you may need to increase this number.
Some of the container configuration parameters are NOT available with this goal:

#### scanIntervalSeconds
Not supported. The forked jetty will not monitor and redeploy the webapp.
#### reload
Not supported. The forked jetty will not redeploy the webapp.
#### httpConnector
Not supported. To define custom connectors use a jetty xml file instead.
#### loginServices
Not supported. To define LoginServices use a jetty xml or context xml file instead.
#### requestLog
Not supported. To define a RequestLog setup, use a jetty xml or context xml file instead.
#### systemProperties
Not supported. Use the jvmArgs parameter to pass system properties to the forked process.
To deploy your unassembled web app to Jetty running in a new JVM:

## mvn jetty:run-forked
Jetty continues to execute until you either:

Press ctrl-c in the terminal window to stop the plugin, which also stops the forked JVM (only if you started with waitForChild=true)
Use jetty:stop to stop the forked JVM, which also stops the plugin.

If you want to set a custom port for the Jetty connector you need to specify it in a jetty xml file rather than setting the connector and port tags. You can specify the location of the jetty.xml using the jettyXml parameter.

## jetty:start

This goal is for use with an execution binding in your pom.xml. It is similar to the jetty:run goal, however it does NOT first execute the build up until the test-compile phase to ensure that all necessary classes and files of the webapp have been generated. This is most useful when you want to control the start and stop of Jetty via execution bindings in your pom.xml.

For example, you can configure the plugin to start your webapp at the beginning of your unit tests and stop at the end. To do this, you need to set up a couple of execution scenarios for the Jetty plugin. You use the pre-integration-test and post-integration-test Maven build phases to trigger the execution and termination of Jetty:
```
<plugin>
  <groupId>org.eclipse.jetty</groupId>
  <artifactId>jetty-maven-plugin</artifactId>
  <version>9.4.5.v20170502</version>
  <configuration>
    <scanIntervalSeconds>10</scanIntervalSeconds>
    <stopKey>foo</stopKey>
    <stopPort>9999</stopPort>
  </configuration>
  <executions>
    <execution>
      <id>start-jetty</id>
      <phase>pre-integration-test</phase>
      <goals>
        <goal>start</goal>
      </goals>
      <configuration>
        <scanIntervalSeconds>0</scanIntervalSeconds>
      </configuration>
    </execution>
    <execution>
      <id>stop-jetty</id>
      <phase>post-integration-test</phase>
       <goals>
         <goal>stop</goal>
       </goals>
     </execution>
  </executions>
</plugin>
```
## jetty:stop

The stop goal stops a running instance of Jetty. To use it, you need to configure the plugin with a special port number and key. That same port number and key will also be used by the other goals that start jetty.

### stopPort
A port number for Jetty to listen on to receive a stop command to cause it to shutdown.
### stopKey
A string value sent to the stopPort to validate the stop command.
### stopWait
The maximum time in seconds that the plugin will wait for confirmation that Jetty has stopped. If false or not specified, the plugin does not wait for confirmation but exits after issuing the stop command.
Here’s a configuration example:
```
<plugin>
  <groupId>org.eclipse.jetty</groupId>
  <artifactId>jetty-maven-plugin</artifactId>
  <version>9.4.5.v20170502</version>
  <configuration>
    <stopPort>9966</stopPort>
    <stopKey>foo</stopKey>
    <stopWait>10</stopWait>
  </configuration>
</plugin>
```
Then, while Jetty is running (in another window), type:

## mvn jetty:stop
The stopPort must be free on the machine you are running on. If this is not the case, you will get an "Address already in use" error message after the "Started ServerConnector …​" message.

## jetty:effective-web-xml

This goal calculates a synthetic web.xml (the "effective web.xml") according to the rules of the Servlet Specification taking into account all sources of discoverable configuration of web components in your application: descriptors (webdefault.xml, web.xml, web-fragment.xml`s, `web-override.xml) and discovered annotations (@WebServlet, @WebFilter, @WebListener). Note that no programmatic declarations of servlets, filters and listeners can be taken into account. The effective web.xml from these combined sources is generated and displayed as maven log output. Other useful information about your webapp that is produced as part of the analysis is also stored as context parameters in the effective-web.xml. The effective-web.xml can be used in conjunction with the Quickstart feature to quickly start your webapp (note that Quickstart is not appropriate for the mvn jetty goals).

The following configuration parameters allow you to save the file:

### deleteOnExit
By default this is true. If set to false, the effective web.xml is generated into a file called effective-web.xml in the build target directory.
### effectiveWebXml
The full path name of a file into which you would like the effective web xml generated.
You can also generate the origin of each element into the effective web.xml file. The origin is either a descriptor eg web.xml,web-fragment.xml,override-web.xml file, or an annotation eg @WebServlet. Some examples of elements with origin attribute information are:
```
<listener origin="DefaultsDescriptor(file:///path/to/distro/etc/webdefault.xml):21">
<listener origin="WebDescriptor(file:///path/to/base/webapps/test-spec/WEB-INF/web.xml):22">
<servlet-class origin="FragmentDescriptor(jar:file:///path/to/base/webapps/test-spec/WEB-INF/lib/test-web-fragment.jar!/META-INF/web-fragment.xml):23">
<servlet-class origin="@WebServlet(com.acme.test.TestServlet):24">
```
To generate origin informatino, use the following configuration parameters on the webApp element:

### originAttribute
The name of the attribute that will contain the origin. By default it is origin.
### generateOrigin
False by default. If true, will force the generation of the originAttribute onto each element.
## Using Overlaid wars

If your webapp depends on other war files, thejetty:run and jetty:run-forked goals are able to merge resources from all of them. It can do so based on the settings of the maven-war-plugin, or if your project does not use the maven-war-plugin to handle the overlays, it can fall back to a simple algorithm to determine the ordering of resources.

## With maven-war-plugin

The maven-war-plugin has a rich set of capabilities for merging resources. The jetty:run and jetty:run-forked goals are able to interpret most of them and apply them during execution of your unassembled webapp. This is probably best seen by looking at a concrete example.

Suppose your webapp depends on the following wars:
```
<dependency>
  <groupId>com.acme</groupId>
  <artifactId>X</artifactId>
  <type>war</type>
</dependency>
<dependency>
  <groupId>com.acme</groupId>
  <artifactId>Y</artifactId>
  <type>war</type>
</dependency>
```
Containing:
```
WebAppX:

 /foo.jsp
 /bar.jsp
 /WEB-INF/web.xml

WebAppY:

 /bar.jsp
 /baz.jsp
 /WEB-INF/web.xml
 /WEB-INF/special.xml
 ```
They are configured for the maven-war-plugin:
```
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-war-plugin</artifactId>
  <version>9.4.5.v20170502</version>
  <configuration>
    <overlays>
      <overlay>
        <groupId>com.acme</groupId>
        <artifactId>X</artifactId>
        <excludes>
          <exclude>bar.jsp</exclude>
        </excludes>
      </overlay>
      <overlay>
        <groupId>com.acme</groupId>
        <artifactId>Y</artifactId>
        <excludes>
          <exclude>baz.jsp</exclude>
        </excludes>
      </overlay>
      <overlay>
      </overlay>
    </overlays>
  </configuration>
</plugin>
```
Then executing jetty:run would yield the following ordering of resources: com.acme.X.war : com.acme.Y.war: ${project.basedir}/src/main/webapp. Note that the current project’s resources are placed last in the ordering due to the empty <overlay/> element in the maven-war-plugin. You can either use that, or specify the <baseAppFirst>false</baseAppFirst> parameter to the jetty-maven-plugin.

Moreover, due to the exclusions specified above, a request for the resource ` bar.jsp` would only be satisfied from com.acme.Y.war. Similarly as baz.jsp is excluded, a request for it would result in a 404 error.

## Without maven-war-plugin

The algorithm is fairly simple, is based on the ordering of declaration of the dependent wars, and does not support exclusions. The configuration parameter <baseAppFirst> (see the section on Configuring Your Webapp for more information) can be used to control whether your webapp’s resources are placed first or last on the resource path at runtime.

For example, suppose our webapp depends on these two wars:
```
<dependency>
  <groupId>com.acme</groupId>
  <artifactId>X</artifactId>
  <type>war</type>
</dependency>
<dependency>
  <groupId>com.acme</groupId>
  <artifactId>Y</artifactId>
  <type>war</type>
</dependency>
```
Suppose the webapps contain:
```
WebAppX:

 /foo.jsp
 /bar.jsp
 /WEB-INF/web.xml

WebAppY:

 /bar.jsp
 /baz.jsp
 /WEB-INF/web.xml
 /WEB-INF/special.xml
 ```
Then our webapp has available these additional resources:
```
/foo.jsp (X)
/bar.jsp (X)
/baz.jsp (Y)
/WEB-INF/web.xml (X)
/WEB-INF/special.xml (Y)
```
## Configuring Security Settings

You can configure LoginServices in the plugin. Here’s an example of setting up the HashLoginService for a webapp:
```
<plugin>
  <groupId>org.eclipse.jetty</groupId>
  <artifactId>jetty-maven-plugin</artifactId>
  <version>9.4.5.v20170502</version>
  <configuration>
    <scanIntervalSeconds>10</scanIntervalSeconds>
    <webApp>
      <contextPath>/test</contextPath>
    </webApp>
    <loginServices>
      <loginService implementation="org.eclipse.jetty.security.HashLoginService">
        <name>Test Realm</name>
        <config>${project.basedir}/src/etc/realm.properties</config>
      </loginService>
    </loginServices>
  </configuration>
</plugin>
```
## Using Multiple Webapp Root Directories

If you have external resources that you want to incorporate in the execution of a webapp, but which are not assembled into war files, you can’t use the overlaid wars method described above, but you can tell Jetty the directories in which these external resources are located. At runtime, when Jetty receives a request for a resource, it searches all the locations to retrieve the resource. It’s a lot like the overlaid war situation, but without the war.

Here is a configuration example:
```
<configuration>
  <webApp>
    <contextPath>/${build.finalName}</contextPath>
    <baseResource implementation="org.eclipse.jetty.util.resource.ResourceCollection">
      <resourcesAsCSV>src/main/webapp,/home/johndoe/path/to/my/other/source,/yet/another/folder</resourcesAsCSV>
    </baseResource>
  </webApp>
</configuration>
```
## Running More than One Webapp

You can use either a jetty.xml file to configure extra (pre-compiled) webapps that you want to deploy, or you can use the <contextHandlers> configuration element to do so. If you want to deploy webapp A, and webapps B and C in the same Jetty instance:

Putting the configuration in webapp A’s pom.xml:

<plugin>
  <groupId>org.eclipse.jetty</groupId>
  <artifactId>jetty-maven-plugin</artifactId>
  <version>9.4.5.v20170502</version>
  <configuration>
    <scanIntervalSeconds>10</scanIntervalSeconds>
    <webApp>
      <contextPath>/test</contextPath>
    </webApp>
    <contextHandlers>
      <contextHandler implementation="org.eclipse.jetty.maven.plugin.JettyWebAppContext">
        <war>${project.basedir}../../B.war</war>
        <contextPath>/B</contextPath>
      </contextHandler>
      <contextHandler implementation="org.eclipse.jetty.maven.plugin.JettyWebAppContext">
        <war>${project.basedir}../../C.war</war>
        <contextPath>/C</contextPath>
      </contextHandler>
    </contextHandlers>
  </configuration>
</plugin>
 Important
If the ContextHandler you are deploying is a webapp, it is essential that you use an org.eclipse.jetty.maven.plugin.JettyWebAppContext instance rather than a standard org.eclipse.jetty.webapp.WebAppContext instance. Only the former will allow the webapp to function correctly in the maven environment.

Alternatively, add a jetty.xml file to webapp A. Copy the jetty.xml file from the Jetty distribution, and then add WebAppContexts for the other 2 webapps:
```
<Ref refid="Contexts">
  <Call name="addHandler">
    <Arg>
      <New class="org.eclipse.jetty.maven.plugin.JettyWebAppContext">
        <Set name="contextPath">/B</Set>
        <Set name="war">../../B.war</Set>
      </New>
    </Arg>
  </Call>
  <Call>
    <Arg>
      <New class="org.eclipse.jetty.maven.plugin.JettyWebAppContext">
        <Set name="contextPath">/C</Set>
        <Set name="war">../../C.war</Set>
      </New>
    </Arg>
  </Call>
</Ref>
```
Then configure the location of this jetty.xml file into webapp A’s jetty plugin:
```
<plugin>
  <groupId>org.eclipse.jetty</groupId>
  <artifactId>jetty-maven-plugin</artifactId>
  <version>9.4.5.v20170502</version>
  <configuration>
    <scanIntervalSeconds>10</scanIntervalSeconds>
    <webApp>
      <contextPath>/test</contextPath>
    </webApp>
    <jettyXml>src/main/etc/jetty.xml</jettyXml>
  </configuration>
</plugin>
```
For either of these solutions, the other webapps must already have been built, and they are not automatically monitored for changes. You can refer either to the packed WAR file of the pre-built webapps or to their expanded equivalents.

## Setting System Properties

You can specify property name/value pairs that Jetty sets as System properties for the execution of the plugin. This feature is useful to tidy up the command line and save a lot of typing.

However, sometimes it is not possible to use this feature to set System properties - sometimes the software component using the System property is already initialized by the time that maven runs (in which case you will need to provide the System property on the command line), or by the time that Jetty runs. In the latter case, you can use the maven properties plugin to define the system properties instead. Here’s an example that configures the logback logging system as the Jetty logger:
```
<plugin>
  <groupId>org.codehaus.mojo</groupId>
  <artifactId>properties-maven-plugin</artifactId>
  <version>1.0-alpha-2</version>
  <executions>
    <execution>
      <goals>
        <goal>set-system-properties</goal>
      </goals>
      <configuration>
        <properties>
          <property>
            <name>logback.configurationFile</name>
            <value>${project.baseUri}/resources/logback.xml</value>
          </property>
        </properties>
      </configuration>
    </execution>
  </executions>
</plugin>
```
 Note
If a System property is already set (for example, from the command line or by the JVM itself), then by default these configured properties DO NOT override them (see below for use of the <force> parameter).

## Specifying System Properties in the POM

Here’s an example of how to specify System properties in the POM:
```
<plugin>
  <groupId>org.eclipse.jetty</groupId>
  <artifactId>jetty-maven-plugin</artifactId>
  <configuration>
    <systemProperties>
      <systemProperty>
        <name>fooprop</name>
        <value>222</value>
      </systemProperty>
    </systemProperties>
    <webApp>
      <contextPath>/test</contextPath>
    </webApp>
  </configuration>
</plugin>
```
To change the default behavior so that these system properties override those on the command line, use the <force> parameter:
```
<plugin>
  <groupId>org.eclipse.jetty</groupId>
  <artifactId>jetty-maven-plugin</artifactId>
  <configuration>
    <systemProperties>
      <force>true</force>
      <systemProperty>
       <name>fooprop</name>
       <value>222</value>
     </systemProperty>
    </systemProperties>
    <webApp>
      <contextPath>/test</contextPath>
    </webApp>
  </configuration>
</plugin>
```
Specifying System Properties in a File

You can also specify your System properties in a file. System properties you specify in this way do not override System properties that set on the command line, by the JVM, or directly in the POM via systemProperties.

Suppose we have a file called mysys.props which contains the following:

> fooprop=222
This can be configured on the plugin like so:
```
<plugin>
  <groupId>org.eclipse.jetty</groupId>
  <artifactId>jetty-maven-plugin</artifactId>
  <configuration>
    <systemPropertiesFile>${project.basedir}/mysys.props</systemPropertiesFile>
    <webApp>
      <contextPath>/test</contextPath>
    </webApp>
  </configuration>
</plugin>
```
You can instead specify the file by setting the System property jetty.systemPropertiesFile on the command line.