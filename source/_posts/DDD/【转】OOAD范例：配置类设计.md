---
title: 【转】OOAD范例：配置类设计
date: 2017-10-19 20:45:56
categories:
    - DDD
tags:
    - DDD
---

来自[OOAD范例：配置类设计](http://www.yyang.io/2016/06/30/design-a-configuration-class/)

**大师做，转载记录用**

在很多应用程序中，我们都需要一个配置类Configuration，通常从一个文本文件中读入配置信息，根据配置调整应用的行为。通过这样的方式，我们可以用相同的代码来适应不同的环境，达到灵活性的目标。

本文探索如何设计好这样的配置类。我们的重点不在于设计的产物——配置类——本身，而是在设计中的权衡取舍，以及取舍的原则。

这里我们以从一个conf.properties文件中读取配置信息为例，以不同的方式读取配置信息。

这个文件的内容如下：

conf.properties
```
birthday=2002-05-11
size=15
closed=true
locked = false
salary=12.5
name=张三
noneValue=
```

配置文件是一个标准的属性文件，在一个配置文件中有一系列的配置项，每个配置项的形式是key=value，其中key为配置项的名称，value为配置项的值。配置项有字符串、数值、布尔、日期等多种类型。

为了方便,本文直接使用单元测试作为配置类的客户代码,即配置类的消费者。

如何在应用代码中获取配置信息？以下提供三种方法，我们随后将分析各自的优缺点。

# 通过JDK自带的Properties类读取配置

JDK中，已经提供了一个Properties类，可以用于从属性文件中读取配置信息。

客户代码如下：

PropertiesTest.java
```
package yang.yu.configuration;
import org.junit.Before;
import org.junit.Test;
import java.io.InputStream;
import java.io.UnsupportedEncodingException;
import java.util.Properties;
import static org.assertj.core.api.Assertions.assertThat;
public class PropertiesTest {
    private String confFile = "/conf.properties";
    private Properties properties;
    @Before
    public void setUp() throws Exception {
        properties = new Properties();
        try(InputStream in = getClass().getResourceAsStream(confFile)) {
            properties.load(in);
        }
    }
    @Test
    public void testGetString() {
        String name = null;
        try {
            String temp = properties.getProperty("name");
            name = new String(temp.getBytes("iso-8859-1"), "utf-8");
            System.out.println(name);
        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
        }
        assertThat(name).isEqualTo("张三");
    }
    @Test
    public void testGetStringWithDefault() {
        String defaultValue = "abc";
        String temp = properties.getProperty("notExists");
        String name = null;
        if (temp == null) {
            name = defaultValue;
        } else {
            try {
                name = new String(temp.getBytes("iso-8859-1"), "utf-8");
            } catch (UnsupportedEncodingException e) {
                e.printStackTrace();
            }
        }
        assertThat(name).isEqualTo("abc");
    }
    @Test
    public void testGetInt() {
        String temp = properties.getProperty("size");
        if (temp == null) {
            throw new ConfigurationKeyNotFoundException();
        }
        int value = -1;
        try {
            value = Integer.parseInt(temp);
        } catch (NumberFormatException e) {
            throw new RuntimeException("Cannot parse string '" + temp + "' to int");
        }
        assertThat(value).isEqualTo(15);
    }
    @Test
    public void testGetIntWithDefault() {
        int defaultValue = 0;
        int value = -1;
        String temp = properties.getProperty("size");
        if (temp == null) {
            value = defaultValue;
        }
        try {
            value = Integer.parseInt(temp);
        } catch (NumberFormatException e) {
            throw new RuntimeException("Cannot parse string '" + temp + "' to int");
        }
        assertThat(value).isEqualTo(15);
    }
    ......
}
```
在这里，我们用单元测试作为配置的客户代码。我们通过Properties类从类路径下的conf.properties文件中读取配置信息，然后通过Properties类的getProperty()方法获取相应的配置项。

虽然从功能上来说，通过Properties类访问配置项没有任何问题，但是客户代码却非常复杂，下面一一讨论。

1. 繁琐

为了获取一个配置值，必须像下面这样输入很多行代码:

```
@Test
public void testGetIntWithDefault() {
    int defaultValue = 0;
    int value = -1;
    String temp = properties.getProperty("size");
    if (temp == null) {
        value = defaultValue;
    }
    try {
        value = Integer.parseInt(temp);
    } catch (NumberFormatException e) {
        throw new RuntimeException("Cannot parse string '" + temp + "' to int");
    }
    assertThat(value).isEqualTo(15);
}
```

因为我们在获取配置值时，必须进行下面的工作：

* 检索key是否存在
* 检索value是否存在
* 如果配置项是字符串类型，必须进行字符集转换
* 如果配置项不是字符串类型，必须进行类型转换
* 如果需要类型转换，必须处理转换异常
* 必须分别处理有缺省值和无缺省值两种情况
* 当有缺省值，但转换失败时，是返回缺省值，还是抛出解析异常？必须灵活应对这两种情况。

2. 重复

由于没有封装，每次访问属性值时都必须输入类似上面的一大段代码，而不只是一行方法调用。因此，系统中充满着重复的代码。业界已经公认，重复是万恶之源。

3. 僵化

我们不能灵活应对多种情况，例如是否有缺省值，日期格式是什么，解析失败时是返回缺省值，还是抛出解析异常等等决策，都直接硬编码到代码之中，不能根据现实需要灵活调整。

4. 脆弱

由于代码复杂，多个关注点相互缠绕，系统非常脆弱，时刻可能因为考虑不周而产生逻辑错误。

直接使用Properties，我们得到的是一个可读性差、可维护性差、复杂、僵化而脆弱的系统。

# 设计一个通用的Configuration类

针对直接采用Properties做配置类的问题，封装是一个非常有效的解决办法。我们可以设计一个通用的Configuration类，在该类中封装了异常处理、字符集编码转换、类型转换、缺省值处理等等方面，使得客户代码可以非常简单、直接，系统的可读性、可维护性和可靠性都得到大幅提升。

配置类的代码如下：

Configuration.java
```
package yang.yu.configuration;
import org.apache.commons.lang3.StringUtils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import yang.yu.configuration.internal.PropertiesFileUtils;
import java.io.*;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Hashtable;
import java.util.Properties;
public class Configuration {
	private static final Logger LOGGER = LoggerFactory.getLogger(Configuration.class);
	private static final String DEFAULT_DATE_FORMAT = "yyyy-MM-dd";
	private Hashtable<String, String> hashtable;
	private String dateFormat = DEFAULT_DATE_FORMAT;
	private boolean defaultWhenParseFailed = false;	//当类型转换失败时是否返回缺省值
	public static Builder builder() {
		return new Builder();
	}
	private Configuration(Hashtable<String, String> hashtable) {
		this.hashtable = hashtable;
	}
	public void setDateFormat(String dateFormat) {
		this.dateFormat = dateFormat;
	}
	public void setDefaultWhenParseFailed(boolean defaultWhenParseFailed) {
		this.defaultWhenParseFailed = defaultWhenParseFailed;
	}
	public String getString(String key, String defaultValue) {
		Assert.notBlank(key, "Key is null or empty!");
        String value = hashtable.get(key);
        return StringUtils.isBlank(value) ? defaultValue : value;
	}
	public String getString(String key) {
		Assert.notBlank(key, "Key is null or empty!");
		if (!hashtable.containsKey(key)) {
			throw new ConfigurationKeyNotFoundException("Configuration key '" + key + "' not found!");
		}
		return hashtable.get(key);
	}
	public int getInt(String key, int defaultValue) {
		if (!hashtable.containsKey(key)) {
			return defaultValue;
		}
		String value = hashtable.get(key);
		try {
			return Integer.parseInt(value);
		} catch (NumberFormatException e) {
			if (defaultWhenParseFailed) {
				return defaultValue;
			}
			throw new ConfigurationValueParseException("'" + value + "' cannot be parsed to int");
		}
	}
	public int getInt(String key) {
		if (!hashtable.containsKey(key)) {
			throw new ConfigurationKeyNotFoundException("Configuration key '" + key + "' not found!");
		}
		String value = hashtable.get(key);
		try {
			return Integer.parseInt(value);
		} catch (NumberFormatException e) {
			throw new ConfigurationValueParseException("'" + value + "' cannot be parsed to int");
		}
	}
    public long getLong(String key, long defaultValue) {
        if (!hashtable.containsKey(key)) {
            return defaultValue;
        }
        String value = hashtable.get(key);
        try {
            return Long.parseLong(value);
        } catch (NumberFormatException e) {
            if (defaultWhenParseFailed) {
                return defaultValue;
            }
            throw new ConfigurationValueParseException("'" + value + "' cannot be parsed to long");
        }
    }
    public long getLong(String key) {
        if (!hashtable.containsKey(key)) {
            throw new ConfigurationKeyNotFoundException("Configuration key '" + key + "' not found!");
        }
        String value = hashtable.get(key);
        try {
            return Long.parseLong(value);
        } catch (NumberFormatException e) {
            throw new ConfigurationValueParseException("'" + value + "' cannot be parsed to long");
        }
    }
    public double getDouble(String key, double defaultValue) {
        if (!hashtable.containsKey(key)) {
            return defaultValue;
        }
        String value = hashtable.get(key);
        try {
            return Double.parseDouble(value);
        } catch (NumberFormatException e) {
            if (defaultWhenParseFailed) {
                return defaultValue;
            }
            throw new ConfigurationValueParseException("'" + value + "' cannot be parsed to double");
        }
    }
    public double getDouble(String key) {
        if (!hashtable.containsKey(key)) {
            throw new ConfigurationKeyNotFoundException("Configuration key '" + key + "' not found!");
        }
        String value = hashtable.get(key);
        try {
            return Double.parseDouble(value);
        } catch (NumberFormatException e) {
            throw new ConfigurationValueParseException("'" + value + "' cannot be parsed to double");
        }
    }
    public boolean getBoolean(String key, boolean defaultValue) {
        if (!hashtable.containsKey(key)) {
            return defaultValue;
        }
        String value = hashtable.get(key);
        if ("true".equalsIgnoreCase(value)) {
            return true;
        }
        if ("false".equalsIgnoreCase(value)) {
            return false;
        }
        if (defaultWhenParseFailed) {
            return Boolean.parseBoolean(value);
        }
        throw new ConfigurationValueParseException("'" + value + "' cannot be parsed to boolean");
    }
    public boolean getBoolean(String key) {
        if (!hashtable.containsKey(key)) {
            throw new ConfigurationKeyNotFoundException("Configuration key '" + key + "' not found!");
        }
        String value = hashtable.get(key);
        if ("true".equalsIgnoreCase(value)) {
            return true;
        }
        if ("false".equalsIgnoreCase(value)) {
            return false;
        }
        throw new ConfigurationValueParseException("'" + value + "' cannot be parsed to boolean");
    }
    public Date getDate(String key, Date defaultValue) {
        if (!hashtable.containsKey(key)) {
            return defaultValue;
        }
        String value = hashtable.get(key);
        try {
            return new SimpleDateFormat(dateFormat).parse(value);
        } catch (ParseException e) {
            if (defaultWhenParseFailed) {
                return defaultValue;
            }
            throw new ConfigurationValueParseException("'" + value + "' cannot be parsed to date");
        }
    }
    public Date getDate(String key) {
        if (!hashtable.containsKey(key)) {
            throw new ConfigurationKeyNotFoundException("Configuration key '" + key + "' not found!");
        }
        String value = hashtable.get(key);
        try {
            return new SimpleDateFormat(dateFormat).parse(value);
        } catch (ParseException e) {
            throw new ConfigurationValueParseException("'" + value + "' cannot be parsed to date");
        }
    }
	public static class Builder {
		private boolean defaultWhenParseFailed = false;	//当类型转换失败时是否返回缺省值
		private Hashtable<String, String> hashtable = new Hashtable();
		private String dateFormat = "yyyy-MM-dd";
		private PropertiesFileUtils pfu = new PropertiesFileUtils("utf-8");
		public Builder fromClasspath(String confFile) {
			String path = getClass().getResource(confFile).getFile();
			return fromFile(path);
		}
		public Builder fromFile(String confFile) {
			return fromFile(new File(confFile));
		}
		public Builder fromFile(File confFile) {
			if (!confFile.exists()) {
				throw new ConfigurationFileNotFoundException();
			}
			if (!confFile.canRead()) {
				throw new ConfigurationFileReadException("Read configuration file is not permitted!");
			}
			InputStream in = null;
			try {
				in = new FileInputStream(confFile);
				Properties props = new Properties();
				props.load(in);
				hashtable = pfu.rectifyProperties(props);
				LOGGER.debug("Load configuration from {} at {}", confFile.getAbsolutePath(), new Date());
			} catch (IOException e) {
				throw new ConfigurationFileReadException("Cannot load config file: " + confFile, e);
			} finally {
				if (in != null) {
					try {
						in.close();
					} catch (IOException e) {
						throw new ConfigurationException("Cannot close input stream.", e);
					}
				}
			}
			return this;
		}
		public Builder dateFormat(String dateFormat) {
			this.dateFormat = dateFormat;
			return this;
		}
		public Builder defaultWhenParseFailed(boolean defaultWhenParseFailed) {
			this.defaultWhenParseFailed = defaultWhenParseFailed;
			return this;
		}
		public Configuration build() {
			if (hashtable.isEmpty()) {
				throw new ConfigurationException("Configuration source not specified!");
			}
			Configuration result = new Configuration(hashtable);
			result.setDateFormat(dateFormat);
			result.setDefaultWhenParseFailed(defaultWhenParseFailed);
			return result;
		}
	}
}
```

通过将异常处理、类型转换、字符编码转换等等功能集中在Configuration类中统一处理，客户端代码卸下这些繁重的、重复性的、易于出错的负担，变得非常简单明了：

ConfigurationTest.java
```
package yang.yu.configuration;
import org.junit.Before;
import org.junit.Test;
import java.io.File;
import java.util.Calendar;
import java.util.Date;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.offset;
public class ConfigurationTest {
    private String confFile = "/conf.properties";
    private Configuration instance;
    
    //more
    ///////////////////////////////////////////3. Int型配置项
    //////////////////3.1. Int型配置项,无缺省值
    /**
     * key存在,value存在,格式正确,应当返回value
     */
    @Test
    public void get_int_without_defaultValue_happy() {
        assertThat(instance.getInt("size")).isEqualTo(15);
    }
    /**
     * key存在,value存在,格式不正确,应当抛出ConfigurationValueParseException异常
     */
    @Test(expected = ConfigurationValueParseException.class)
    public void get_int_without_defaultValue_and_with_invalid_value() {
        instance.getInt("name");
    }
    /**
     * key存在,value不存在,应当抛出ConfigurationValueParseException异常
     */
    @Test(expected = ConfigurationValueParseException.class)
    public void get_int_without_defaultValue_and_without_value() {
        instance.getInt("noneValue");
    }
    /**
     * key不存在,应当抛出ConfigurationKeyNotFoundException异常
     */
    @Test(expected = ConfigurationKeyNotFoundException.class)
    public void get_int_without_defaultValue_and_without_key() {
        instance.getInt("noneKey");
    }
    /////////////3.2. Int型配置项,有缺省值
    /**
     * key存在, value存在,格式正确,应当返回value
     */
    @Test
    public void get_int_with_defaultValue_and_with_value() {
        assertThat(instance.getInt("size", 1000)).isEqualTo(15);
    }
    /**
     * key存在,value存在,格式不正确,defaultWhenParseFailed=true,应当返回缺省值
     */
    @Test
    public void get_int_with_defaultValue_and_with_invalid_value_and_defaultWhenParseFailed_is_true() {
        instance.setDefaultWhenParseFailed(true);
        assertThat(instance.getInt("name", 1000)).isEqualTo(1000);
    }
    /**
     * key存在,value存在,格式不正确,defaultWhenParseFailed=false,应当抛出ConfigurationValueParseException异常
     */
    @Test(expected = ConfigurationValueParseException.class)
    public void get_int_with_defaultValue_and_with_invalid_value_and_defaultWhenParseFailed_is_false() {
        instance.setDefaultWhenParseFailed(false);
        instance.getInt("name", 1000);
    }
    /**
     * key存在,value不存在,defaultWhenParseFailed=true,应当返回缺省值
     */
    @Test
    public void get_int_with_defaultValue_and_without_value_and_defaultWhenParseFailed_is_true() {
        instance.setDefaultWhenParseFailed(true);
        assertThat(instance.getInt("noneValue", 1000)).isEqualTo(1000);
    }
    /**
     * key存在,value不存在,defaultWhenParseFailed=false,应当抛出ConfigurationValueParseException异常
     */
    @Test(expected = ConfigurationValueParseException.class)
    public void get_int_with_defaultValue_and_without_value_and_defaultWhenParseFailed_is_false() {
        instance.setDefaultWhenParseFailed(false);
        instance.getInt("noneValue", 1000);
    }
    /**
     * key不存在,应当返回缺省值
     */
    @Test
    public void get_int_with_defaultValue_and_without_key() {
        assertThat(instance.getInt("noneKey", 1000)).isEqualTo(1000);
    }
    
	//more    
}
```

要获取一个整数值，我们只需要这样调用：

``int size = configuration.getInt("size");``

如果想要在配置项不存在时返回缺省值，我们只需要这样调用：

``int size = configuration.getInt("size"， 0);``

读取配置信息是一个通用性的需求，几乎在每个项目中都有这样的需要。抽象出Configuration类之后，我们可以将它作为公司级通用类库，供给所有的项目引用，使得其他项目不再需要编写重复的配置文件读取代码。

但是，直接使用通用的Configuration类，仍有不尽人意的方面。例如，我要读取Boolean类型的closed配置项，必须这样编写代码：

```
if (configuration.getBoolean("closed")) {
	......
}
```

这样的语句仍然与我的领域语言隔了一层，是面向实现而不是面向意图的。我真正需要的是这样的代码：

```
if (configuration.isClosed()) {
	......
}
```

closed不再是一个由5个字母组成的字符串，而是领域语言isClosed()的一部分。

下面说明怎样设计这样的一个面向客户领域的、特化的Configuration类。

# 设计一个特化的AppConfiguration类

特化的AppConfiguration类采用客户领域的语言编写，将配置项中无意义的字符串key转化为方法名称：

AppConfiguration.java
```
package yang.yu.configuration;
import java.util.Date;
public class AppConfiguration {
    private static String confFile = "/conf.properties";
    private static final String KEY_BIRTHDAY = "birthday";
    private static final String KEY_SIZE = "size";
    private static final String KEY_CLOSED = "closed";
    private static final String KEY_LOCKED = "locked";
    private static final String KEY_SALARY = "salary";
    private static final String KEY_NAME = "name";
    private static final double HIGH_SALARY_THRESHOLD = 10000;
    private Configuration configuration;
    public AppConfiguration() {
        this.configuration = Configuration.builder()
                .fromClasspath(confFile)
                .dateFormat("yyyy-MM-dd")
                .defaultWhenParseFailed(true)
                .build();
    }
    public AppConfiguration(Configuration configuration) {
        this.configuration = configuration;
    }
    public Date birthday() {
        return configuration.getDate(KEY_BIRTHDAY);
    }
    public int size() {
        return configuration.getInt(KEY_SIZE);
    }
    public boolean isClosed() {
        return configuration.getBoolean(KEY_CLOSED);
    }
    public boolean isLocked() {
        return configuration.getBoolean(KEY_LOCKED);
    }
    public double salary() {
        return configuration.getDouble(KEY_SALARY);
    }
    public boolean isHighSalaryLevel() {
        return salary() >= HIGH_SALARY_THRESHOLD;
    }
    public String name() {
        return configuration.getString("name");
    }
}
```

客户端代码更加简单、直接，可读性更强：

AppConfigurationTest.java
```
package yang.yu.configuration;
import org.junit.Before;
import org.junit.Test;
import java.util.Calendar;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.offset;
public class AppConfigurationTest {
    private AppConfiguration instance;
    @Before
    public void setUp() throws Exception {
        instance = new AppConfiguration();
    }
    @Test
    public void birthday() throws Exception {
        Date expected = DateUtils.createDate(2002, Calendar.MAY, 11);
        assertThat(instance.birthday()).isEqualTo(expected);
    }
    @Test
    public void size() throws Exception {
        assertThat(instance.size()).isEqualTo(15);
    }
    @Test
    public void isClosed() throws Exception {
        assertThat(instance.isClosed()).isTrue();
    }
    @Test
    public void isLocked() throws Exception {
        assertThat(instance.isLocked()).isFalse();
    }
    @Test
    public void salary() throws Exception {
        assertThat(instance.salary()).isCloseTo(12.5, offset(0.00001));
    }
    @Test
    public void isHighSalaryLevel() throws Exception {
        assertThat(instance.isHighSalaryLevel()).isFalse();
    }
    @Test
    public void name() throws Exception {
        assertThat(instance.name()).isEqualTo("张三");
    }
}
```
提供应用特定的配置类好处很明显：

1. 通过将配置项从字符串转换成方法名，减少了错误录入的可能

如果我们这些读取配置：

``boolean closed = configuration.getBoolean("closed");``

如果不小心，很容易把字符串closed写错。要命的是，这个错误IDE和编译器都无法捕获，只有在运行时才会发现。

这样的配置：

``boolean closed = configuration.isClosed();``

就不太可能写错，即使写错了，IDE和编译器会替你发现。

2. 面向领域编程

在分析设计的时候，我们应该通过在软件中采用问题域的词汇来作为软件类、方法、属性、变量的名称来缩小问题域和解决方案域之间的语义距离。

``configuration.isClosed();``

比起

``configuration.getBoolean("closed");``

更接近问题域的语言。

3. 支持衍生配置项

在AppConfiguration类中，我创建了一个衍生配置项：

```
public boolean isHighSalaryLevel() {
    return salary() >= HIGH_SALARY_THRESHOLD;
}
```

该配置项并不直接存储于conf.properties中。

# 总结

在这个项目中主要应用了两个设计技巧:

* 封装
* 泛化与特化

## 封装

在这个项目中,我们在两个地方基于不同的目的应用了封装。

1. 通过Configuration封装Properties, 目的是隐藏技术复杂性，减轻客户端代码的负担。
2. 通过AppConfiguration封装Configuration，目的是更契合特定领域的需要，面向意图编程。

## 泛化（generalization）与特化（specialization）

在本项目中,我们同时提供了通用的配置类Configuration和专门领域的配置类AppConfiguration。Configuration是AppConfiguration的泛化，AppConfiguration是Configuration的特化。

Configuration的目标是重用，因此必须更一般化，可以提供任意多个设置项，提供更多的可配置内容（例如dateFormat, defaultWhenParseFailed等），以便可以灵活应用于多种不同的环境；AppConfiguration的目标是紧密契合当前项目的需要，因此有一个固定的设置项集合，并且剔除了不必要的灵活性（dateFormat直接设置为yyyy-MM-dd，defaultWhenParseFailed直接设置为true）。

最重要的是记住：

``泛化以扩大外延——在大多数项目中得到重用；``
``特化以增加内涵——高度契合当前项目的需要。``
