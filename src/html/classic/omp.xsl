<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    version="1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:str="http://exslt.org/strings"
    xmlns:func="http://exslt.org/functions"
    xmlns:gsa="http://openvas.org"
    xmlns:gsa-i18n="http://openvas.org/i18n"
    xmlns:vuln="http://scap.nist.gov/schema/vulnerability/0.4"
    xmlns:cpe-lang="http://cpe.mitre.org/language/2.0"
    xmlns:scap-core="http://scap.nist.gov/schema/scap-core/0.1"
    xmlns:cve="http://scap.nist.gov/schema/feed/vulnerability/2.0"
    xmlns:cvss="http://scap.nist.gov/schema/cvss-v2/0.2"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:patch="http://scap.nist.gov/schema/patch/0.1"
    xmlns:meta="http://scap.nist.gov/schema/cpe-dictionary-metadata/0.2"
    xmlns:ns6="http://scap.nist.gov/schema/scap-core/0.1"
    xmlns:config="http://scap.nist.gov/schema/configuration/0.1"
    xmlns:cpe="http://cpe.mitre.org/dictionary/2.0"
    xmlns:oval="http://oval.mitre.org/XMLSchema/oval-common-5"
    xmlns:oval_definitions="http://oval.mitre.org/XMLSchema/oval-definitions-5"
    xmlns:dfncert="http://www.dfn-cert.de/dfncert.dtd"
    xmlns:atom="http://www.w3.org/2005/Atom"
    xsi:schemaLocation="http://scap.nist.gov/schema/configuration/0.1 http://nvd.nist.gov/schema/configuration_0.1.xsd http://scap.nist.gov/schema/scap-core/0.3 http://nvd.nist.gov/schema/scap-core_0.3.xsd http://cpe.mitre.org/dictionary/2.0 http://cpe.mitre.org/files/cpe-dictionary_2.2.xsd http://scap.nist.gov/schema/scap-core/0.1 http://nvd.nist.gov/schema/scap-core_0.1.xsd http://scap.nist.gov/schema/cpe-dictionary-metadata/0.2 http://nvd.nist.gov/schema/cpe-dictionary-metadata_0.2.xsd"
    xmlns:date="http://exslt.org/dates-and-times"
    xmlns:exslt="http://exslt.org/common"
    exclude-result-prefixes="vuln cpe-lang scap-core cve cvss xsi patch meta ns6 config cpe oval oval_definitions dfncert atom"
    extension-element-prefixes="str func date exslt gsa gsa-i18n">
  <xsl:output
      method="html"
      doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
      doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
      encoding="UTF-8"/>

<!--
Greenbone Security Assistant
$Id$
Description: Greenbone Management Protocol (GMP) stylesheet

Authors:
Matthew Mundell <matthew.mundell@greenbone.net>
Jan-Oliver Wagner <jan-oliver.wagner@greenbone.net>
Michael Wiegand <michael.wiegand@greenbone.net>
Timo Pollmeier <timo.pollmeier@greenbone.net>

Copyright:
Copyright (C) 2009-2015 Greenbone Networks GmbH

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
-->


<!-- BEGIN GLOBAL VARIABLES -->

<xsl:variable name="icon-width" select="19"/>
<xsl:variable name="trash-actions-width" select="3 + (2 * $icon-width)"/>

<!-- BEGIN XPATH FUNCTIONS -->

<func:function name="gsa:envelope-filter">
  <xsl:choose>
    <xsl:when test="string-length (/envelope/params/filter) &gt; 0 and string-length (/envelope/params/filter_extra) &gt; 0">
      <func:result select="concat (/envelope/params/filter, ' ', /envelope/params/filter_extra)"/>
    </xsl:when>
    <xsl:otherwise>
      <func:result select="concat (/envelope/params/filter, /envelope/params/filter_extra)"/>
    </xsl:otherwise>
  </xsl:choose>
</func:function>

<func:function name="gsa:may">
  <xsl:param name="name"/>
  <xsl:param name="permissions" select="permissions"/>
  <func:result select="gsa:may-op ($name) and (boolean ($permissions/permission[name='Everything']) or boolean ($permissions/permission[name=$name]))"/>
</func:function>

<xsl:variable name="capabilities" select="/envelope/capabilities/help_response/schema"/>

<func:function name="gsa:may-op">
  <xsl:param name="name"/>
  <func:result select="boolean ($capabilities/command[gsa:lower-case (name) = gsa:lower-case ($name)])"/>
</func:function>

<func:function name="gsa:may-clone">
  <xsl:param name="type"/>
  <xsl:param name="owner" select="owner"/>
  <func:result select="gsa:may-op (concat ('create_', $type))"/>
</func:function>

<func:function name="gsa:may-get-trash">
  <func:result select="boolean ($capabilities/command[substring (gsa:lower-case (name), 1, 4) = 'get_' and gsa:lower-case (name) != 'get_version' and gsa:lower-case (name) != 'get_info' and gsa:lower-case (name) != 'get_nvts' and gsa:lower-case (name) != 'get_system_reports'  and gsa:lower-case (name) != 'get_settings'])"/>
</func:function>

<func:function name="gsa:build-levels">
  <xsl:param name="filters"></xsl:param>
  <func:result>
    <xsl:for-each select="$filters/filter">
      <xsl:choose>
        <xsl:when test="text()='High'">h</xsl:when>
        <xsl:when test="text()='Medium'">m</xsl:when>
        <xsl:when test="text()='Low'">l</xsl:when>
        <xsl:when test="text()='Log'">g</xsl:when>
        <xsl:when test="text()='False Positive'">f</xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </func:result>
</func:function>

<func:function name="gsa:build-filter">
  <xsl:param name="filters"></xsl:param>
  <xsl:param name="replace"></xsl:param>
  <xsl:param name="with"></xsl:param>

  <func:result>
    <xsl:for-each select="$filters/keywords/keyword">
      <xsl:choose>
        <xsl:when test="column = $replace">
          <xsl:value-of select="$with"/>
          <xsl:text> </xsl:text>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="column"/>
          <xsl:value-of select="relation"/>
          <xsl:value-of select="value"/>
          <xsl:text> </xsl:text>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </func:result>
</func:function>

<func:function name="gsa:join">
  <xsl:param name="nodes"/>
  <func:result>
    <xsl:for-each select="$nodes">
      <xsl:value-of select="name"/>
      <xsl:text> </xsl:text>
    </xsl:for-each>
  </func:result>
</func:function>

<func:function name="gsa:build-css-classes">
  <xsl:param name="prefix"/>
  <xsl:param name="nodes"/>

  <xsl:variable name="classes" select="exslt:node-set($nodes)/classes"/>

  <func:result>
    <xsl:for-each select="$classes/class">
      <xsl:value-of select="$prefix"/><xsl:value-of select="."/><xsl:text> </xsl:text>
    </xsl:for-each>
  </func:result>
</func:function>

<func:function name="gsa:actions-width">
  <xsl:param name="icon-count"/>
  <func:result select="15 + ($icon-count * $icon-width)"/>
</func:function>

<func:function name="gsa:token">
  <xsl:choose>
    <xsl:when test="string-length (/envelope/params/debug) = 0">
      <func:result select="concat ('&amp;token=', /envelope/token)"/>
    </xsl:when>
    <xsl:otherwise>
      <func:result select="concat ('&amp;token=', /envelope/token, '&amp;debug=', /envelope/params/debug)"/>
    </xsl:otherwise>
  </xsl:choose>
</func:function>

<func:function name="gsa:capitalise">
  <xsl:param name="string"/>
  <func:result select="concat (gsa:upper-case (substring ($string, 1, 1)), substring ($string, 2))"/>
</func:function>

<func:function name="gsa:lower-case">
  <xsl:param name="string"/>
  <func:result select="translate($string, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')"/>
</func:function>

<func:function name="gsa:upper-case">
  <xsl:param name="string"/>
  <func:result select="translate($string, 'abcdefghijklmnopqrstuvwxyz', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ')"/>
</func:function>

<func:function name="gsa:escape-js">
  <xsl:param name="string"/>
  <xsl:variable name='apos'>'</xsl:variable>
  <!-- Escape as XML entities where applicable -->
  <func:result select="str:replace (str:replace (str:replace (str:replace (str:replace (str:replace (
                       $string, '&amp;', '&amp;amp;'), '\', '\x2F'), '&quot;', '&amp;quot;'), $apos, '&amp;apos;'), '&lt;', '&amp;lt;'), '&gt;', '&amp;gt;')"/>
</func:function>

<func:function name="gsa:date-tz">
  <xsl:param name="time"></xsl:param>
  <func:result>
    <!-- 2013-03-26T13:15:00-04:00 -->
    <!-- 2013-03-26T13:15:00Z -->
    <!-- 2013-03-26T13:15:00+04:00 -->
    <xsl:variable name="length" select="string-length ($time)"/>
    <xsl:if test="$length &gt; 0">
      <xsl:choose>
        <xsl:when test="substring ($time, $length) = 'Z'">
          <xsl:value-of select="'UTC'"/>
        </xsl:when>
        <xsl:when test="contains ('+-', substring ($time, $length - 5, 1)) and (substring ($time, $length - 2, 1) = ':')">
          <xsl:value-of select="substring ($time, $length - 5)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="'ERROR'"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </func:result>
</func:function>

<func:function name="gsa:long-time-tz">
  <xsl:param name="time"></xsl:param>
  <func:result>
    <xsl:if test="string-length ($time) &gt; 0">
      <xsl:value-of select="concat (date:day-abbreviation ($time), ' ', date:month-abbreviation ($time), ' ', date:day-in-month ($time), ' ', format-number(date:hour-in-day($time), '00'), ':', format-number(date:minute-in-hour($time), '00'), ':', format-number(date:second-in-minute($time), '00'), ' ', date:year($time), ' ', gsa:date-tz($time))"/>
    </xsl:if>
  </func:result>
</func:function>

<func:function name="gsa:long-time">
  <xsl:param name="time"></xsl:param>
  <func:result>
    <xsl:if test="string-length ($time) &gt; 0">
      <xsl:value-of select="concat (date:day-abbreviation ($time), ' ', date:month-abbreviation ($time), ' ', date:day-in-month ($time), ' ', format-number(date:hour-in-day($time), '00'), ':', format-number(date:minute-in-hour($time), '00'), ':', format-number(date:second-in-minute($time), '00'), ' ', date:year($time))"/>
    </xsl:if>
  </func:result>
</func:function>

<func:function name="gsa:date">
  <xsl:param name="datetime"></xsl:param>
  <func:result>
    <xsl:if test="string-length ($datetime) &gt; 0">
      <xsl:value-of select="concat (date:day-abbreviation ($datetime), ' ', date:month-abbreviation ($datetime), ' ', date:day-in-month ($datetime), ' ', date:year($datetime))"/>
    </xsl:if>
  </func:result>
</func:function>

<func:function name="gsa:type-many">
  <xsl:param name="type"></xsl:param>
  <func:result>
    <xsl:choose>
      <xsl:when test="$type = 'info' or $type = 'allinfo'">
        <xsl:value-of select="$type"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$type"/><xsl:text>s</xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </func:result>
</func:function>

<func:function name="gsa:html-attribute-quote">
  <xsl:param name="text"/>
  <func:result>
    <xsl:value-of select="translate ($text, '&quot;', '&amp;quot;')"/>
  </func:result>
</func:function>

<!-- This is only safe for HTML attributes. -->
<func:function name="gsa:param-or">
  <xsl:param name="name"/>
  <xsl:param name="alternative"/>
  <xsl:choose>
    <xsl:when test="/envelope/params/node()[name()=$name]">
      <func:result>
        <xsl:value-of select="gsa:html-attribute-quote (/envelope/params/node()[name()=$name])"/>
      </func:result>
    </xsl:when>
    <xsl:when test="/envelope/params/_param[name=$name]">
      <func:result>
        <xsl:value-of select="gsa:html-attribute-quote (/envelope/params/_param[name=$name]/value)"/>
      </func:result>
    </xsl:when>
    <xsl:otherwise>
      <func:result>
        <xsl:value-of select="$alternative"/>
      </func:result>
    </xsl:otherwise>
  </xsl:choose>
</func:function>

<func:function name="gsa:get-nvt-tag">
    <xsl:param name="tags"/>
    <xsl:param name="name"/>
  <xsl:variable name="after">
    <xsl:value-of select="substring-after (nvt/tags, concat ($name, '='))"/>
  </xsl:variable>
  <xsl:choose>
      <xsl:when test="contains ($after, '|')">
        <func:result select="substring-before ($after, '|')"/>
      </xsl:when>
      <xsl:otherwise>
        <func:result select="$after"/>
      </xsl:otherwise>
  </xsl:choose>
</func:function>

<func:function name="gsa:cvss-risk-factor">
  <xsl:param name="cvss_score"/>
  <xsl:variable name="type" select="/envelope/severity"/>
  <xsl:variable name="threat">
    <xsl:choose>
      <xsl:when test="$type = 'classic'">
        <xsl:choose>
          <xsl:when test="$cvss_score = 0.0">Log</xsl:when>
          <xsl:when test="$cvss_score &gt;= 0.1 and $cvss_score &lt;= 2.0">Low</xsl:when>
          <xsl:when test="$cvss_score &gt;= 2.1 and $cvss_score &lt;= 5.0">Medium</xsl:when>
          <xsl:when test="$cvss_score &gt;= 5.1 and $cvss_score &lt;= 8.0">High</xsl:when>
          <xsl:when test="$cvss_score &gt;= 8.1 and $cvss_score &lt;= 10.0">High</xsl:when>
          <xsl:otherwise>None</xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="$type = 'pci-dss'">
        <xsl:choose>
          <xsl:when test="$cvss_score &gt;= 0.0 and $cvss_score &lt; 4.0">Log</xsl:when>
          <xsl:when test="$cvss_score &gt;= 4.0">High</xsl:when>
          <xsl:otherwise>None</xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- Default to nist/bsi -->
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$cvss_score = 0.0">Log</xsl:when>
          <xsl:when test="$cvss_score &gt;= 0.1 and $cvss_score &lt;= 3.9">Low</xsl:when>
          <xsl:when test="$cvss_score &gt;= 4.0 and $cvss_score &lt;= 6.9">Medium</xsl:when>
          <xsl:when test="$cvss_score &gt;= 7.0 and $cvss_score &lt;= 10.0">High</xsl:when>
          <xsl:otherwise>None</xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <func:result select="$threat"/>
</func:function>

<func:function name="gsa:result-cvss-risk-factor">
  <xsl:param name="cvss_score"/>
  <xsl:variable name="threat">
    <xsl:choose>
      <xsl:when test="$cvss_score &gt; 0.0">
        <xsl:value-of select="gsa:cvss-risk-factor($cvss_score)"/>
      </xsl:when>
      <xsl:when test="$cvss_score = 0.0">Log</xsl:when>
      <xsl:when test="$cvss_score = -1.0">False Positive</xsl:when>
      <xsl:when test="$cvss_score = -2.0">Debug</xsl:when>
      <xsl:when test="$cvss_score = -3.0">Error</xsl:when>
      <xsl:otherwise>N/A</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <func:result select="$threat"/>
</func:function>

<func:function name="gsa:risk-factor-max-cvss">
  <xsl:param name="threat"/>
  <xsl:param name="type"><xsl:value-of select="/envelope/severity"/></xsl:param>
  <xsl:variable name="cvss">
    <xsl:choose>
      <xsl:when test="$type = 'classic'">
        <xsl:choose>
          <xsl:when test="gsa:lower-case($threat) = 'none' or gsa:lower-case($threat) = 'log'">0.0</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'low'">2.0</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'medium'">5.0</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'high'">10.0</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'critical'">10.0</xsl:when>
          <xsl:otherwise>0.0</xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:when test="$type = 'pci-dss'">
        <xsl:choose>
          <xsl:when test="gsa:lower-case($threat) = 'none' or gsa:lower-case($threat) = 'log'">3.9</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'low'">3.9</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'medium'">3.9</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'high'">10.0</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'critical'">10.0</xsl:when>
          <xsl:otherwise>0.0</xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- Default to nist/bsi -->
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="gsa:lower-case($threat) = 'none' or gsa:lower-case($threat) = 'log'">0.0</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'low'">3.9</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'medium'">6.9</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'high'">10.0</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'critical'">10.0</xsl:when>
          <xsl:otherwise>0.0</xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <func:result select="$cvss"/>
</func:function>

<func:function name="gsa:risk-factor-min-cvss">
  <xsl:param name="threat"/>
  <xsl:param name="type"><xsl:value-of select="/envelope/severity"/></xsl:param>
  <xsl:variable name="cvss">
    <xsl:choose>
      <xsl:when test="$type = 'classic'">
        <xsl:choose>
          <xsl:when test="gsa:lower-case($threat) = 'none' or gsa:lower-case($threat) = 'log'">0.0</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'low'">0.1</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'medium'">2.1</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'high'">5.1</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'critical'">10.0</xsl:when>
          <xsl:otherwise>0.0</xsl:otherwise>
        </xsl:choose>
      </xsl:when>

      <xsl:when test="$type = 'pci-dss'">
        <xsl:choose>
          <xsl:when test="gsa:lower-case($threat) = 'none' or gsa:lower-case($threat) = 'none'">0.0</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'low'">3.9</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'medium'">3.9</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'high'">4.0</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'critical'">10.0</xsl:when>
          <xsl:otherwise>0.0</xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <!-- Default to nist/bsi -->
      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="gsa:lower-case($threat) = 'none' or gsa:lower-case($threat) = 'log'">0.0</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'low'">0.1</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'medium'">4.0</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'high'">7.0</xsl:when>
          <xsl:when test="gsa:lower-case($threat) = 'critical'">10.0</xsl:when>
          <xsl:otherwise>0.0</xsl:otherwise>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <func:result select="$cvss"/>
</func:function>

<func:function name="gsa:threat-color">
  <xsl:param name="threat"/>
  <xsl:variable name="color">
    <xsl:choose>
      <xsl:when test="gsa:lower-case($threat) = 'high'">red</xsl:when>
      <xsl:when test="gsa:lower-case($threat) = 'medium'">orange</xsl:when>
      <xsl:when test="gsa:lower-case($threat) = 'low'">lightskyblue</xsl:when>
      <xsl:when test="gsa:lower-case($threat) = 'none' or gsa:lower-case($threat) = 'log'">silver</xsl:when>
      <xsl:otherwise></xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <func:result select="$color"/>
</func:function>

<func:function name="gsa:column-filter-name">
  <xsl:param name="type"/>
  <func:result select="str:replace (str:replace (gsa:lower-case ($type), '&#xa0;', '_'), ' ', '_')"/>
</func:function>

<func:function name="gsa:type-string">
  <xsl:param name="type"/>
  <func:result select="str:replace (gsa:lower-case ($type), ' ', '_')"/>
</func:function>

<func:function name="gsa:command-type-plural">
  <xsl:param name="command"/>
  <xsl:variable name="type"
                select="gsa:command-type ($command)"/>
  <xsl:choose>
    <xsl:when test="$type = 'NVT family'">
      <func:result select="'NVT families'"/>
    </xsl:when>
    <xsl:otherwise>
      <func:result select="concat ($type, 's')"/>
    </xsl:otherwise>
  </xsl:choose>
</func:function>

<func:function name="gsa:command-type">
  <xsl:param name="command"/>
  <xsl:variable name="after"
                select="substring-after (str:replace (gsa:lower-case ($command), '_', ' '), ' ')"/>
  <xsl:variable name="type">
    <xsl:choose>
      <xsl:when test="substring ($after, string-length ($after)) = 's'">
        <xsl:value-of select="substring ($after, 1, string-length ($after) - 1)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$after"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:choose>
    <xsl:when test="$type = 'lsc credential'">
      <func:result select="'credential'"/>
    </xsl:when>
    <xsl:when test="$type = 'config'">
      <func:result select="'scan config'"/>
    </xsl:when>
    <xsl:when test="$type = 'nvt'">
      <func:result select="'NVT'"/>
    </xsl:when>
    <xsl:when test="$type = 'nvt familie'">
      <func:result select="'NVT family'"/>
    </xsl:when>
    <xsl:otherwise>
      <func:result select="$type"/>
    </xsl:otherwise>
  </xsl:choose>
</func:function>

<func:function name="gsa:join-capital">
  <xsl:param name="nodes"/>
  <func:result>
    <xsl:for-each select="$nodes">
      <xsl:value-of select="gsa:capitalise (text ())"/>
      <xsl:if test="position() != last()">
        <xsl:text> </xsl:text>
      </xsl:if>
    </xsl:for-each>
  </func:result>
</func:function>

<func:function name="gsa:command-type-label">
  <xsl:param name="command"/>
  <func:result select="gsa:capitalise (gsa:command-type ($command))"/>
</func:function>

<func:function name="gsa:type-name">
  <xsl:param name="type"/>
  <xsl:choose>
    <xsl:when test="$type = 'nvt' or $type = 'cve' or $type = 'cpe'">
      <func:result select="gsa:upper-case ($type)"/>
    </xsl:when>
    <xsl:when test="$type = 'os'">
      <func:result select="'Operating System'"/>
    </xsl:when>
    <xsl:when test="$type = 'ovaldef'">
      <func:result select="'OVAL Definition'"/>
    </xsl:when>
    <xsl:when test="$type = 'vuln'">
      <func:result select="'Vulnerability'"/>
    </xsl:when>
    <xsl:when test="$type = 'cert_bund_adv'">
      <func:result select="'CERT-Bund Advisory'"/>
    </xsl:when>
    <xsl:when test="$type = 'dfn_cert_adv'">
      <func:result select="'DFN-CERT Advisory'"/>
    </xsl:when>
    <xsl:when test="$type = 'allinfo'">
      <func:result select="'All SecInfo'"/>
    </xsl:when>
    <xsl:otherwise>
      <func:result select="gsa:join-capital (str:split ($type, '_'))"/>
    </xsl:otherwise>
  </xsl:choose>
</func:function>

<func:function name="gsa:type-name-plural">
  <xsl:param name="type"/>
  <xsl:choose>
    <xsl:when test="$type = 'vuln'">
      <func:result select="'Vulnerabilities'"/>
    </xsl:when>
    <xsl:when test="$type = 'cert_bund_adv'">
      <func:result select="'CERT-Bund Advisories'"/>
    </xsl:when>
    <xsl:when test="$type = 'dfn_cert_adv'">
      <func:result select="'DFN-CERT Advisories'"/>
    </xsl:when>
    <xsl:when test="$type = 'allinfo'">
      <func:result select="'All SecInfo'"/>
    </xsl:when>
    <xsl:otherwise>
      <func:result select="concat(gsa:type-name ($type), 's')"/>
    </xsl:otherwise>
  </xsl:choose>
</func:function>

<func:function name="gsa:field-name">
  <xsl:param name="field"/>
  <xsl:choose>
    <xsl:when test="$field = 'created'">
      <func:result select="'creation time'"/>
    </xsl:when>
    <xsl:when test="$field = 'modified'">
      <func:result select="'modification time'"/>
    </xsl:when>
    <xsl:when test="$field = 'qod'">
      <func:result select="'QoD'"/>
    </xsl:when>
    <xsl:when test="$field = 'qod_type'">
      <func:result select="'QoD type'"/>
    </xsl:when>
    <xsl:otherwise>
      <func:result select="translate ($field, '_', ' ')"/>
    </xsl:otherwise>
  </xsl:choose>
</func:function>

<func:function name="gsa:alert-in-trash">
  <xsl:for-each select="alert">
    <xsl:if test="trash/text() != '0'">
      <func:result>1</func:result>
    </xsl:if>
  </xsl:for-each>
  <func:result>0</func:result>
</func:function>

<func:function name="gsa:table-row-class">
  <xsl:param name="position"/>
  <func:result>
    <xsl:choose>
      <xsl:when test="$position &lt; 0"></xsl:when>
      <xsl:when test="$position mod 2 = 0">even</xsl:when>
      <xsl:otherwise>odd</xsl:otherwise>
    </xsl:choose>
  </func:result>
</func:function>

<func:function name="gsa:date-diff-text">
  <xsl:param name="difference"/>

  <xsl:variable name="fromepoch"
                select="date:add ('1970-01-01T00:00:00Z', $difference)"/>
  <xsl:variable name="seconds"
                select="date:second-in-minute($fromepoch)"/>
  <xsl:variable name="minutes"
                select="date:minute-in-hour($fromepoch)"/>
  <xsl:variable name="hours"
                select="date:hour-in-day($fromepoch)"/>
  <xsl:variable name="days"
                select="date:day-in-year($fromepoch) - 1"/>

  <func:result>
      <xsl:if test="$days">
          <xsl:value-of select="concat (gsa-i18n:strformat (gsa:n-i18n ('%1 day', '%1 days', $days, ''), $days), ' ')"/>
      </xsl:if>
      <xsl:if test="$hours">
          <xsl:value-of select="concat (gsa-i18n:strformat (gsa:n-i18n ('%1 hour', '%1 hours', $hours, ''), $hours), ' ')"/>
      </xsl:if>
      <xsl:if test="$minutes">
          <xsl:value-of select="concat (gsa-i18n:strformat (gsa:n-i18n ('%1 minute', '%1 minutes', $minutes, ''), $minutes), ' ')"/>
      </xsl:if>
      <xsl:if test="$seconds">
          <xsl:value-of select="concat (gsa-i18n:strformat (gsa:n-i18n ('%1 second', '%1 seconds', $seconds, ''), $seconds), ' ')"/>
      </xsl:if>
  </func:result>
</func:function>

<func:function name="gsa:date-diff">
  <xsl:param name="start"/>
  <xsl:param name="end"/>

  <xsl:variable name="difference" select="date:difference ($start, $end)"/>
  <func:result>
    <xsl:value-of select="gsa:date-diff-text ($difference)"/>
  </func:result>
</func:function>

<func:function name="gsa:report-host-has-os">
  <xsl:param name="report"/>
  <xsl:param name="ip"/>
  <xsl:param name="os"/>
  <func:result>
    <xsl:choose>
      <xsl:when test="$report/host[ip = $ip and detail/name = 'best_os_cpe' and detail/value = $os]">1</xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </func:result>
</func:function>

<func:function name="gsa:host-has-unknown-os">
  <xsl:param name="report"/>
  <xsl:param name="ip"/>
  <func:result>
    <xsl:choose>
      <xsl:when test="$report/host[ip = $ip and ((detail/name = 'best_os_cpe') = 0)]">1</xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </func:result>
</func:function>

<func:function name="gsa:report-section-title">
  <xsl:param name="section"/>
  <xsl:param name="type"/>
  <func:result>
    <xsl:choose>
      <xsl:when test="$section = 'results' and $type = 'delta'"><xsl:value-of select="gsa:i18n ('Report: Delta Results')"/></xsl:when>
      <xsl:when test="$section = 'results'"><xsl:value-of select="gsa:i18n ('Report: Results')"/></xsl:when>
      <xsl:when test="$section = 'summary' and $type = 'delta'"><xsl:value-of select="gsa:i18n ('Report: Delta Summary and Download')"/></xsl:when>
      <xsl:when test="$section = 'summary'"><xsl:value-of select="gsa:i18n ('Report: Summary and Download')"/></xsl:when>
      <xsl:when test="$section = 'hosts'"><xsl:value-of select="gsa:i18n ('Report: Hosts')"/></xsl:when>
      <xsl:when test="$section = 'ports'"><xsl:value-of select="gsa:i18n ('Report: Ports')"/></xsl:when>
      <xsl:when test="$section = 'os'"><xsl:value-of select="gsa:i18n ('Report: Operating Systems')"/></xsl:when>
      <xsl:when test="$section = 'apps'"><xsl:value-of select="gsa:i18n ('Report: Applications')"/></xsl:when>
      <xsl:when test="$section = 'cves'"><xsl:value-of select="gsa:i18n ('Report: CVEs')"/></xsl:when>
      <xsl:when test="$section = 'closed_cves'"><xsl:value-of select="gsa:i18n ('Report: Closed CVEs')"/></xsl:when>
      <xsl:when test="$section = 'topology'"><xsl:value-of select="gsa:i18n ('Report: Topology')"/></xsl:when>
      <xsl:when test="$section = 'ssl_certs'"><xsl:value-of select="gsa:i18n ('Report: SSL Certificates')"/></xsl:when>
      <xsl:when test="$section = 'errors'"><xsl:value-of select="gsa:i18n ('Report: Error Messages')"/></xsl:when>
    </xsl:choose>
  </func:result>
</func:function>

<func:function name="gsa:has-long-word">
  <xsl:param name="string"/>
  <xsl:param name="max" select="44"/>
  <func:result select="count (str:split ($string, ' ')[string-length (.) &gt; $max]) &gt; 0"/>
</func:function>

<func:function name="gsa:permission-description">
  <xsl:param name="name"/>
  <xsl:param name="resource"/>
  <xsl:variable name="lower" select="gsa:lower-case ($name)"/>
  <xsl:variable name="has-resource" select="boolean ($resource) and string-length ($resource/type) &gt; 0"/>
  <func:result>
    <xsl:choose>
      <xsl:when test="$has-resource and $lower = 'super'">
        <xsl:value-of select="gsa:i18n ('has super access to ')"/>
        <xsl:value-of select="gsa:i18n (gsa:command-type ($lower), 'Type Lower')"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="$resource/type"/>
        <xsl:text> </xsl:text>
        <xsl:value-of select="$resource/name"/>
      </xsl:when>
      <xsl:when test="$lower = 'super'">
        <xsl:value-of select="gsa:i18n ('has super access to all users')"/>
      </xsl:when>
      <xsl:when test="$lower = 'authenticate'">
        <xsl:value-of select="gsa:i18n ('may login')"/>
      </xsl:when>
      <xsl:when test="$lower = 'commands'">
        <xsl:value-of select="gsa:i18n ('may run multiple GMP commands in one')"/>
      </xsl:when>
      <xsl:when test="$lower = 'everything'">
        <xsl:value-of select="gsa:i18n ('has all permissions')"/>
      </xsl:when>
      <xsl:when test="$lower = 'empty_trashcan'">
        <xsl:value-of select="gsa:i18n ('may empty the trashcan')"/>
      </xsl:when>
      <xsl:when test="$lower = 'get_dependencies'">
        <xsl:value-of select="gsa:i18n ('may get the dependencies of NVTs')"/>
      </xsl:when>
      <xsl:when test="$lower = 'get_version'">
        <xsl:value-of select="gsa:i18n ('may get version information')"/>
      </xsl:when>
      <xsl:when test="$lower = 'help'">
        <xsl:value-of select="gsa:i18n ('may get the help text')"/>
      </xsl:when>
      <xsl:when test="$lower = 'modify_auth'">
        <xsl:value-of select="gsa:i18n ('has write access to the authentication configuration')"/>
      </xsl:when>
      <xsl:when test="$lower = 'restore'">
        <xsl:value-of select="gsa:i18n ('may restore items from the trashcan')"/>
      </xsl:when>
      <!-- i18n with concat : see dynamic_strings.xsl - permission-descriptions -->
      <xsl:when test="substring-before ($lower, '_') = 'create'">
        <xsl:value-of select="gsa:i18n (concat ('may create a new ', gsa:command-type ($lower)))"/>
      </xsl:when>
      <xsl:when test="$lower = 'get_info'">
        <xsl:value-of select="gsa:i18n ('has read access to SecInfo')"/>
      </xsl:when>
      <xsl:when test="$has-resource and substring-before ($lower, '_') = 'delete'">
        <xsl:value-of select="gsa-i18n:strformat (gsa:i18n (concat ('may delete ', gsa:command-type ($lower), ' %1')), $resource/name)"/>
      </xsl:when>
      <xsl:when test="substring-before ($lower, '_') = 'delete'">
        <xsl:value-of select="gsa:i18n (concat ('may delete an existing ', gsa:command-type ($lower)))"/>
      </xsl:when>
      <xsl:when test="$has-resource and substring-before ($lower, '_') = 'get'">
        <xsl:value-of select="gsa-i18n:strformat (gsa:i18n (concat ('has read access to ', gsa:command-type ($lower), ' %1')), $resource/name)"/>
      </xsl:when>
      <xsl:when test="substring-before ($lower, '_') = 'get'">
        <xsl:value-of select="gsa:i18n (concat ('has read access to ', gsa:command-type-plural ($lower)))"/>
      </xsl:when>
      <xsl:when test="$has-resource and substring-before ($lower, '_') = 'modify'">
        <xsl:value-of select="gsa-i18n:strformat (gsa:i18n (concat ('has write access to ', gsa:command-type ($lower), ' %1')), $resource/name)"/>
      </xsl:when>
      <xsl:when test="substring-before ($lower, '_') = 'modify'">
        <xsl:value-of select="gsa:i18n (concat ('has write access to ', gsa:command-type-plural ($lower)))"/>
      </xsl:when>

      <xsl:when test="substring-before ($lower, '_') = 'describe'">
        <xsl:variable name="described" select="substring-after ($lower, '_')"/>
        <xsl:variable name="text">
          <xsl:choose>
            <xsl:when test="$described = 'auth'">
              <xsl:value-of select="gsa:i18n ('may get details about the authentication configuration')"/>
            </xsl:when>
            <xsl:otherwise>
              <!-- This should only be a fallback for unexpected output -->
              <xsl:value-of select="gsa-i18n:strformat (gsa:i18n ('may get details about %1') , $described)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$text"/>
      </xsl:when>

      <xsl:when test="substring-before ($lower, '_') = 'sync'">
        <xsl:variable name="to_sync" select="substring-after ($lower, '_')"/>
        <xsl:variable name="text">
          <xsl:choose>
            <xsl:when test="$to_sync = 'cert'">
              <xsl:value-of select="gsa:i18n ('may sync the CERT feed')"/>
            </xsl:when>
            <xsl:when test="$to_sync = 'feed'">
              <xsl:value-of select="gsa:i18n ('may sync the NVT feed')"/>
            </xsl:when>
            <xsl:when test="$to_sync = 'scap'">
              <xsl:value-of select="gsa:i18n ('may sync the SCAP feed')"/>
            </xsl:when>
            <xsl:otherwise>
              <!-- This should only be a fallback for unexpected output -->
              <xsl:value-of select="gsa-i18n:strformat (gsa:i18n ('may sync %1'), $to_sync)"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:value-of select="$text"/>
      </xsl:when>

      <xsl:when test="contains ($lower, '_')">
        <!-- see dynamic_strings.xsl - permission-descriptions (verify_...) -->
        <xsl:value-of select="gsa:i18n (concat ('may ', substring-before ($lower, '_'), ' ', gsa:command-type-plural ($lower)))"/>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$lower"/></xsl:otherwise>
    </xsl:choose>
  </func:result>
</func:function>

<func:function name="gsa:view_details_title">
  <xsl:param name="type"/>
  <xsl:param name="name"/>
  <xsl:variable name="cap_type" select="gsa:type-name($type)"/>
  <func:result>
    <!-- i18n with concat : see dynamic_strings.xsl - type-details-long -->
    <xsl:value-of select="gsa-i18n:strformat (gsa:i18n (concat ('View details of ', $cap_type, ' %1')), $name)"/>
  </func:result>
</func:function>

<func:function name="gsa:is_absolute_path">
  <xsl:param name="path"/>

  <xsl:variable name="first"
    select="substring ($path, 1, 1)"/>

  <xsl:choose>
    <xsl:when test="$first = '/'">
      <func:result select="true()"/>
    </xsl:when>
    <xsl:otherwise>
      <func:result select="false()"/>
    </xsl:otherwise>
  </xsl:choose>
</func:function>

<func:function name="gsa:column_is_extra">
  <xsl:param name="column"/>
  <xsl:choose>
    <xsl:when test="$column = 'apply_overrides' or $column = 'autofp' or $column = 'rows' or $column = 'first' or $column = 'sort' or $column = 'sort-reverse' or $column = 'notes' or $column = 'overrides' or $column = 'timezone' or $column = 'result_hosts_only' or $column = 'levels' or $column = 'min_qod' or $column = 'delta_states'">
      <func:result select="true()"/>
    </xsl:when>
    <xsl:otherwise>
      <func:result select="false()"/>
    </xsl:otherwise>
  </xsl:choose>
</func:function>

<!-- BEGIN NAMED TEMPLATES -->

<xsl:template name="shy-long-rest">
  <xsl:param name="string"/>
  <xsl:param name="max" select="44"/>
  <xsl:param name="chunk" select="5"/>
  <xsl:text disable-output-escaping="yes">&amp;shy;</xsl:text>
  <xsl:value-of select="substring ($string, 1, $chunk)"/>
  <xsl:if test="string-length ($string) &gt; $chunk">
    <xsl:call-template name="shy-long-rest">
      <xsl:with-param name="string"
                      select="substring ($string, $chunk + 1)"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>

<xsl:template name="shy-long-words">
  <xsl:param name="string"/>
  <xsl:param name="max" select="44"/>
  <xsl:param name="chunk" select="5"/>
  <xsl:for-each select="str:split ($string, ' ')">
    <xsl:choose>
      <xsl:when test="string-length (.) &gt; $max">
        <xsl:value-of select="substring (., 1, $chunk)"/>
        <xsl:call-template name="shy-long-rest">
          <xsl:with-param name="string"
                          select="substring (., $chunk + 1)"/>
          <xsl:with-param name="chunk" select="$chunk"/>
        </xsl:call-template>
        <xsl:text> </xsl:text>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="."/>
        <xsl:text> </xsl:text>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:for-each>
</xsl:template>

<!-- Currently only a very simple formatting method to produce
     nice HTML from a structured text:
     - create paragraphs for each text block separated with a empty line
-->
<xsl:template name="structured-text">
  <xsl:param name="string"/>

  <xsl:for-each select="str:split($string, '&#10;&#10;')">
    <p>
      <xsl:value-of select="."/>
    </p>
  </xsl:for-each>
</xsl:template>

<xsl:template name="feedback-icon">
<!-- You may fill in here to_name and to_adress and un-comment the block
     to enable a feedback button for support or similar purposes. -->
<!--
  <xsl:param name="to_name" select="'FILL IN NAME'"/>
  <xsl:param name="to_address" select="'FILL IN EMAIL ADDRESS'"/>
  <xsl:param name="subject" select="'Feedback'"/>
  <xsl:param name="body" select="'Dear%20{str:encode-uri ($to_name, true ())},&#xA;&#xA;'"/>
  <a class="icon icon-sm" href="mailto:{str:encode-uri ($to_name, true ())}%20%3C{str:encode-uri ($to_address, true ())}%3E?subject={str:encode-uri ($subject, true ())}&amp;body=Dear%20{str:encode-uri ($to_name, true ())},&#xA;&#xA;{str:encode-uri ($body, true ())}">
    <img src="img/feedback.svg" title="{gsa:i18n ('Send feedback to')} {$to_name}" alt="{gsa:i18n('Feedback')}"/>
  </a>
-->
</xsl:template>

<xsl:template name="filter-window-pager">
  <xsl:param name="type"/>
  <xsl:param name="list"/>
  <xsl:param name="count"/>
  <xsl:param name="filtered_count"/>
  <xsl:param name="full_count"/>
  <xsl:param name="extra_params"/>

  <xsl:variable name="get_cmd">
    <xsl:choose>
      <xsl:when test="$type='report_result'">
        <xsl:value-of select="'get_report_section'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat ('get_', gsa:type-many($type))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:choose>
    <xsl:when test="$count &gt; 0">
      <xsl:variable name="last" select="$list/@start + $count - 1"/>

      <!-- Table has rows. -->

      <div class="pager">

        <!-- Left icons. -->
        <div class="pagination pagination-left">
          <xsl:choose>
            <xsl:when test = "$list/@start &gt; 1">
              <a href="?cmd={$get_cmd}{$extra_params}&amp;filter=first=1 rows={$list/@max} {filters/term}&amp;token={/envelope/token}"
                class="icon icon-sm">
                <img src="/img/first.svg" title="{gsa:i18n ('First', 'Pagination')}"/></a>
            </xsl:when>
            <xsl:otherwise>
              <img class="icon icon-sm" src="/img/first_inactive.svg" title="{gsa:i18n ('Already on first page', 'Pagination')}"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:choose>
            <xsl:when test="$list/@start > $list/@max and $list/@max &gt; 0">
              <a href="?cmd={$get_cmd}{$extra_params}&amp;filter=first={$list/@start - $list/@max} rows={$list/@max} {filters/term}&amp;token={/envelope/token}"
                class="icon icon-sm">
                <img src="/img/previous.svg" title="{gsa:i18n ('Previous', 'Pagination')}"/></a>
            </xsl:when>
            <xsl:when test="$list/@start &gt; 1 and $list/@max &gt; 0">
              <a href="?cmd={$get_cmd}{$extra_params}&amp;filter=first=1 rows={$list/@max} {filters/term}&amp;token={/envelope/token}"
                class="icon icon-sm">
                <img src="/img/previous.svg" title="{gsa:i18n ('Previous', 'Pagination')}"/></a>
            </xsl:when>
            <xsl:otherwise>
              <img class="icon icon-sm" src="/img/previous_inactive.svg" title="{gsa:i18n ('Already on first page', 'Pagination')}"/>
            </xsl:otherwise>
          </xsl:choose>
        </div>

        <!-- Text. -->
        <div class="pagination pagination-text">
          <xsl:value-of select="gsa-i18n:strformat (gsa:i18n ('%1 - %2 of %3'), $list/@start, $last, $filtered_count)"/>
        </div>

        <!-- Right icons. -->
        <div class="pagination pagination-right">
          <xsl:choose>
            <xsl:when test = "$last &lt; $filtered_count">
              <a href="?cmd={$get_cmd}{$extra_params}&amp;filter=first={$list/@start + $list/@max} rows={$list/@max} {filters/term}&amp;token={/envelope/token}"
                class="icon icon-sm">
                <img src="/img/next.svg" title="{gsa:i18n ('Next', 'Pagination')}"/></a>
            </xsl:when>
            <xsl:otherwise>
              <img class="icon icon-sm" src="/img/next_inactive.svg" title="{gsa:i18n ('Already on last page', 'Pagination')}"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:choose>
            <xsl:when test = "$last &lt; $filtered_count">
              <a href="?cmd={$get_cmd}{$extra_params}&amp;filter=first={floor(($filtered_count - 1) div $list/@max) * $list/@max + 1} rows={$list/@max} {filters/term}&amp;token={/envelope/token}"
                class="icon icon-sm">
                <img src="/img/last.svg" title="{gsa:i18n ('Last', 'Pagination')}"/></a>
            </xsl:when>
            <xsl:otherwise>
              <img class="icon icon-sm" src="/img/last_inactive.svg" title="{gsa:i18n ('Already on last page', 'Pagination')}"/>
            </xsl:otherwise>
          </xsl:choose>
        </div>
      </div>
    </xsl:when>
  </xsl:choose>
</xsl:template>

<xsl:template name="filter-criteria">
  <xsl:variable name="operator_count" select="count (filters/keywords/keyword[column='' and (value='and' or value='not' or value='or')])"/>
  <xsl:for-each select="filters/keywords/keyword[not (gsa:column_is_extra (column) or (column = 'task_id' and $operator_count = 0))]">
    <xsl:value-of select="column"/>
    <xsl:choose>
      <xsl:when test="column = '' and relation != '='">
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="relation"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="boolean (quoted)">"</xsl:if>
    <xsl:value-of select="value"/>
    <xsl:if test="boolean (quoted)">"</xsl:if>
    <xsl:text> </xsl:text>
  </xsl:for-each>
</xsl:template>

<xsl:template name="filter-extra">
  <xsl:variable name="operator_count" select="count (filters/keywords/keyword[column='' and (value='and' or value='not' or value='or')])"/>
  <xsl:for-each select="filters/keywords/keyword[gsa:column_is_extra (column) or (column = 'task_id' and $operator_count = 0)]">
    <xsl:value-of select="column"/>
    <xsl:choose>
      <xsl:when test="column = '' and relation != '='">
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="relation"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="boolean (quoted)">"</xsl:if>
    <xsl:value-of select="value"/>
    <xsl:if test="boolean (quoted)">"</xsl:if>
    <xsl:text> </xsl:text>
  </xsl:for-each>
</xsl:template>

<xsl:template name="filter-window-part">
  <xsl:param name="type"/>
  <xsl:param name="list"/>
  <xsl:param name="extra_params"/>
  <xsl:param name="columns"/>
  <xsl:param name="filter_options" select="''"/>
  <xsl:param name="filters" select="../filters"/>
  <xsl:param name="full-count" select="1"/>

  <xsl:variable name="filter_options_nodes" select="exslt:node-set($filter_options)"/>

  <xsl:variable name="criteria">
    <xsl:call-template name="filter-criteria"/>
  </xsl:variable>
  <xsl:variable name="extra">
    <xsl:call-template name="filter-extra"/>
  </xsl:variable>
  <xsl:variable name="get_cmd">
    <xsl:choose>
      <xsl:when test="$type='report_result'">
        <xsl:value-of select="'get_report_section'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat ('get_', gsa:type-many($type))"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="extra_params_string">
    <xsl:for-each select="exslt:node-set($extra_params)/param">
      <xsl:text>&amp;</xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text>=</xsl:text>
      <xsl:value-of select="value"/>
    </xsl:for-each>
  </xsl:variable>

  <xsl:variable name="max">
    <xsl:choose>
      <xsl:when test="$full-count&lt;1">
        <xsl:value-of select="1"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$full-count"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="min_qod_value">
    <xsl:choose>
      <xsl:when test="not (filters/keywords/keyword[column = 'min_qod']/value != '')">
        <xsl:value-of select="70"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="filters/keywords/keyword[column = 'min_qod']/value"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <div>
    <form class="form-inline" action="" method="get" enctype="multipart/form-data" name="filterform">
      <input type="hidden" name="token" value="{/envelope/token}"/>
      <input type="hidden" name="cmd" value="{$get_cmd}"/>
      <xsl:for-each select="exslt:node-set($extra_params)/param">
        <input type="hidden" name="{name}" value="{value}"/>
      </xsl:for-each>
      <div class="form-group">
        <label for="filtername" class="control-label">
          <b><xsl:value-of select="gsa:i18n ('Filter')"/></b>:
        </label>
        <input type="text" name="filter" size="53"
          id="filtername"
          class="form-control"
          value="{$criteria}"
          maxlength="1000"/>
        <input type="image"
          name="Update Filter"
          class="icon icon-sm"
          title="{gsa:i18n ('Update Filter')}"
          src="/img/refresh.svg"
          alt="{gsa:i18n ('Update', 'Action Verb')}"/>
        <a href="?token={/envelope/token}&amp;cmd={$get_cmd}&amp;filt_id=--{$extra_params_string}"
          class="icon icon-sm"
          title="{gsa:i18n ('Reset Filter')}">
          <img src="/img/delete.svg" />
        </a>
        <a href="/help/powerfilter.html?token={/envelope/token}"
          class="icon icon-sm"
          title="{gsa:i18n ('Help')}: {gsa:i18n ('Powerfilter')}">
          <img src="/img/help.svg" />
        </a>
        <a href="#" class="icon icon-sm edit-filter-action-icon" data-id="filterbox">
          <img src="/img/edit.svg"/>
        </a>
        <xsl:variable name="extras">
          <xsl:for-each select="exslt:node-set($extra_params)/param">
            <xsl:value-of select="concat ('&amp;', name, '=', value)"/>
          </xsl:for-each>
        </xsl:variable>
        <input type="hidden" name="filter_extra" value="{$extra}" />
      </div>
      <div class="footnote">
        <xsl:value-of select="$extra"/>
      </div>
    </form>
  </div>
  <xsl:if test="gsa:may-op ('create_filter')">
    <div>
      <form class="form-inline" action="" method="post" enctype="multipart/form-data">
        <div class="form-group">
          <input type="hidden" name="token" value="{/envelope/token}"/>
          <input type="hidden" name="cmd" value="create_filter"/>
          <input type="hidden" name="caller" value="{/envelope/current_page}"/>
          <input type="hidden" name="comment" value=""/>
          <input type="hidden" name="term" value="{filters/term}"/>
          <xsl:choose>
            <xsl:when test="$type = 'report_result'">
              <input type="hidden" name="optional_resource_type" value="result"/>
              <input type="hidden" name="next" value="get_report_section"/>
            </xsl:when>
            <xsl:otherwise>
              <input type="hidden" name="optional_resource_type" value="{$type}"/>
              <input type="hidden" name="next" value="get_{gsa:type-many($type)}"/>
            </xsl:otherwise>
          </xsl:choose>
          <input type="hidden" name="filter" value="{gsa:envelope-filter ()}"/>
          <xsl:for-each select="exslt:node-set($extra_params)/param">
            <input type="hidden" name="{name}" value="{value}"/>
          </xsl:for-each>
          <input type="text" name="name" value="" size="10"
            class="form-control"
            maxlength="80"/>

          <xsl:variable name="type-name">
            <xsl:choose>
              <xsl:when test="$type = 'report_result'">
                <xsl:value-of select="Result"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="gsa:type-name ($type)"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <!-- i18n with concat : see dynamic_strings.xsl - type-new-filter -->
          <input type="image"
            name="New Filter"
            class="icon icon-sm"
            src="/img/new.svg"
            alt="{gsa:i18n ('New Filter')}"
            title="{gsa:i18n (concat ('New ', $type-name, ' Filter from current term'))}" />
        </div>
      </form>
    </div>
  </xsl:if>
  <xsl:if test="gsa:may-op ('get_filters')">
    <div>
      <form class="form-inline" action="" method="get" name="switch_filter" enctype="multipart/form-data">
        <div class="form-group">
          <input type="hidden" name="token" value="{/envelope/token}"/>
          <xsl:choose>
            <xsl:when test="$type = 'report_result'">
              <input type="hidden" name="cmd" value="get_report_section"/>
            </xsl:when>
            <xsl:otherwise>
              <input type="hidden" name="cmd" value="get_{gsa:type-many($type)}"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:for-each select="exslt:node-set($extra_params)/param">
            <input type="hidden" name="{name}" value="{value}"/>
          </xsl:for-each>
          <select style="margin-bottom: 0px; max-width: 100px;" name="filt_id" onchange="switch_filter.submit()">
            <option value="--">--</option>
            <xsl:variable name="id" select="filters/@id"/>
            <xsl:for-each select="$filters/get_filters_response/filter">
              <xsl:choose>
                <xsl:when test="@id = $id">
                  <option value="{@id}" selected="1"><xsl:value-of select="name"/></option>
                </xsl:when>
                <xsl:otherwise>
                  <option value="{@id}"><xsl:value-of select="name"/></option>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
          </select>
        </div>
      </form>
    </div>
  </xsl:if>

  <div id="filterbox" style="display: none">
    <form class="form-horizontal" action="" method="get" name="filterform">
      <xsl:choose>
        <xsl:when test="$type = 'report_result'">
          <input type="hidden" name="cmd" value="get_report_section"/>
        </xsl:when>
        <xsl:otherwise>
          <input type="hidden" name="cmd" value="get_{gsa:type-many($type)}"/>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:for-each select="exslt:node-set($extra_params)/param">
        <input type="hidden" name="{name}" value="{value}"/>
      </xsl:for-each>
      <input type="hidden" name="token" value="{/envelope/token}"/>
      <input type="hidden" name="build_filter" value="0"/>
      <div class="form-group">
        <label for="dfilter" class="col-2 control-label">
          <xsl:value-of select="gsa:i18n ('Filter')"/>:
        </label>
        <div class="col-10">
          <input type="text" name="filter" size="53"
            id="dfilter"
            class="form-control"
            value="{$criteria}"
            maxlength="1000"/>
        </div>
      </div>
      <xsl:if test="filters/keywords/keyword[column='task_id'] and ../get_tasks_response/task">
        <div class="form-group">
          <xsl:variable name="task_id"
            select="filters/keywords/keyword[column='task_id']/value"/>
          <label for="task_id" class="col-2 control-label"><xsl:value-of select="gsa:i18n ('Task')"/>:</label>
          <div class="col-10">
            <select class="col-10 form-control" id="task_id" name="task_id" size="1">
              <xsl:for-each select="../get_tasks_response/task">
                <xsl:call-template name="opt">
                  <xsl:with-param name="value" select="@id"/>
                  <xsl:with-param name="content" select="name/text()"/>
                  <xsl:with-param name="select-value" select="$task_id"/>
                </xsl:call-template>
              </xsl:for-each>
            </select>
          </div>
        </div>
      </xsl:if>
      <xsl:if test="delta or $filter_options_nodes/option[text()='delta_states']">
        <div class="form-group">
          <label class="col-2 control-label">
            <xsl:value-of select="gsa:i18n ('Show delta results')"/>:
          </label>
          <span class="col-10">
            <span class="checkbox">
              <label>
                <xsl:choose>
                  <xsl:when test="filters/delta/same = 0">
                    <input type="checkbox" name="delta_state_same" value="1"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <input type="checkbox" name="delta_state_same"
                      value="1" checked="1"/>
                  </xsl:otherwise>
                </xsl:choose>
                = <xsl:value-of select="gsa:i18n ('same', 'Delta Result')"/>
              </label>
            </span>
            <span class="checkbox">
              <label>
                <xsl:choose>
                  <xsl:when test="filters/delta/new = 0">
                    <input type="checkbox" name="delta_state_new" value="1"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <input type="checkbox" name="delta_state_new"
                      value="1" checked="1"/>
                  </xsl:otherwise>
                </xsl:choose>
                + <xsl:value-of select="gsa:i18n ('new', 'Delta Result')"/>
              </label>
            </span>
            <span class="checkbox">
              <label>
                <xsl:choose>
                  <xsl:when test="filters/delta/gone = 0">
                    <input type="checkbox" name="delta_state_gone" value="1"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <input type="checkbox" name="delta_state_gone"
                      value="1" checked="1"/>
                  </xsl:otherwise>
                </xsl:choose>
                &#8722; <xsl:value-of select="gsa:i18n ('gone', 'Delta Result')"/>
              </label>
            </span>
            <span class="checkbox">
              <label>
                <xsl:choose>
                  <xsl:when test="filters/delta/changed = 0">
                    <input type="checkbox" name="delta_state_changed" value="1"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <input type="checkbox" name="delta_state_changed"
                      value="1" checked="1"/>
                  </xsl:otherwise>
                </xsl:choose>
                ~ <xsl:value-of select="gsa:i18n ('changed', 'Delta Result')"/>
              </label>
            </span>
          </span>
        </div>
      </xsl:if>
      <xsl:if test="filters/keywords/keyword[column='apply_overrides'] or $filter_options_nodes/option[text()='apply_overrides']">
        <div class="form-group">
          <xsl:variable name="apply_overrides"
            select="filters/keywords/keyword[column='apply_overrides']/value"/>
          <!-- TODO: Rename "overrides" to "apply_overrides" where it
                      controls whether overrides are applied -->
          <xsl:variable name="apply_overrides_param_name">
            <xsl:choose>
              <xsl:when test="$type = 'report_result'">apply_overrides</xsl:when>
              <xsl:otherwise>overrides</xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <label class="col-2 control-label">
            <xsl:value-of select="gsa:i18n ('Apply overrides')"/>:
          </label>
          <div class="col-10 checkbox">
            <label>
              <xsl:choose>
                <xsl:when test="$apply_overrides = 0">
                  <input type="checkbox" name="{$apply_overrides_param_name}"
                    value="1"/>
                </xsl:when>
                <xsl:otherwise>
                  <input type="checkbox" name="{$apply_overrides_param_name}"
                    value="1" checked="1"/>
                </xsl:otherwise>
              </xsl:choose>
            </label>
          </div>
        </div>
      </xsl:if>
      <xsl:if test="filters/keywords/keyword[column='autofp'] or $filter_options_nodes/option[text()='autofp']">
        <div class="form-group">
          <label class="col-2 control-label"><xsl:value-of select="gsa:i18n ('Auto-FP')"/>:</label>
          <div class="col-10 checkbox">
            <label>
              <xsl:choose>
                <xsl:when test="filters/keywords/keyword[column='autofp']/value = 0">
                  <input class="form-enable-control" id="autofp" type="checkbox"
                    name="autofp" value="1" disable-on="not(:checked)"/>
                </xsl:when>
                <xsl:otherwise>
                  <input class="form-enable-control" id="autofp" type="checkbox"
                    name="autofp" value="1" checked="1" disable-on="not(:checked)"/>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:value-of select="gsa:i18n ('Trust vendor security updates')"/>
            </label>
            <div>
              <label class="radio-inline">
                <xsl:choose>
                  <xsl:when test="filters/keywords/keyword[column='autofp']/value = 2">
                    <input type="radio" name="autofp_value" value="1"
                      class="form-enable-item--autofp"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <input type="radio" name="autofp_value" value="1" checked="1"
                      class="form-enable-item--autofp"/>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:value-of select="gsa:i18n ('Full CVE match')"/>
              </label>
              <label class="radio-inline">
                <xsl:choose>
                  <xsl:when test="filters/keywords/keyword[column='autofp']/value = 2">
                    <input type="radio" name="autofp_value" value="2" checked="1"
                      class="form-enable-item--autofp"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <input type="radio" name="autofp_value" value="2"
                      class="form-enable-item--autofp"/>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:value-of select="gsa:i18n ('Partial CVE match')"/>
              </label>
            </div>
          </div>
        </div>
      </xsl:if>
      <xsl:if test="filters/keywords/keyword[column='notes'] or $filter_options_nodes/option[text()='notes']">
        <div class="form-group">
          <label class="col-2 control-label">
            <xsl:value-of select="gsa:i18n ('Show Notes')"/>:
          </label>
          <div class="col-10 checkbox">
            <label>
              <xsl:choose>
                <xsl:when test="filters/keywords/keyword[column='notes']/value = '0'">
                  <input type="checkbox" name="notes" value="1"/>
                </xsl:when>
                <xsl:otherwise>
                  <input type="checkbox" name="notes" value="1"
                    checked="1"/>
                </xsl:otherwise>
              </xsl:choose>
            </label>
          </div>
        </div>
      </xsl:if>
      <xsl:if test="filters/keywords/keyword[column='overrides'] or $filter_options_nodes/option[text()='overrides']">
        <div class="form-group">
          <label class="col-2 control-label">
            <xsl:value-of select="gsa:i18n ('Show Overrides')"/>:
          </label>
          <div class="col-10 checkbox">
            <label>
              <xsl:choose>
                <xsl:when test="filters/keywords/keyword[column='overrides']/value = '0'">
                  <input type="checkbox" name="overrides" value="1"/>
                </xsl:when>
                <xsl:otherwise>
                  <input type="checkbox" name="overrides" value="1"
                    checked="1"/>
                </xsl:otherwise>
              </xsl:choose>
            </label>
          </div>
        </div>
      </xsl:if>
      <xsl:if test="filters/keywords/keyword[column='result_hosts_only'] or $filter_options_nodes/option[text()='result_hosts_only']">
        <div class="form-group">
          <label class="col-2 control-label">
            <xsl:value-of select="gsa:i18n ('Only show hosts that have results')"/>:
          </label>
          <div class="col-10 checkbox">
            <label>
              <xsl:choose>
                <xsl:when test="filters/keywords/keyword[column='result_hosts_only']/value = '0'">
                  <input type="checkbox" name="result_hosts_only" value="1"/>
                </xsl:when>
                <xsl:otherwise>
                  <input type="checkbox" name="result_hosts_only" value="1"
                    checked="1"/>
                </xsl:otherwise>
              </xsl:choose>
            </label>
          </div>
        </div>
      </xsl:if>
      <xsl:if test="filters/keywords/keyword[column='min_qod'] or $filter_options_nodes/option[text()='min_qod']">
        <div class="form-group">
          <label class="col-2 control-label">
            <xsl:value-of select="gsa:i18n ('QoD')"/>:
          </label>
          <span class="col-10">
            <div class="form-item">
              <label>
                <xsl:value-of select="gsa:i18n ('must be at least', 'QoD')"/>
              </label>
              <xsl:text> </xsl:text>
              <div min="0" max="100" step="1" class="slider" name="min_qod" type="int" value="{$min_qod_value}"></div>
            </div>
          </span>
        </div>
      </xsl:if>
      <xsl:if test="filters/keywords/keyword[column='timezone'] or $filter_options_nodes/option[text()='timezone']">
        <div class="form-group">
          <label class="col-2 control-label">
            <xsl:value-of select="gsa:i18n ('Timezone')"/>:
          </label>
          <span class="col-10">
            <xsl:call-template name="timezone-select">
              <xsl:with-param name="timezone" select="timezone"/>
              <xsl:with-param name="input-name" select="'timezone'"/>
            </xsl:call-template>
          </span>
        </div>
      </xsl:if>

      <xsl:if test="filters/keywords/keyword[column='levels'] or $filter_options_nodes/option[text()='levels']">
        <div class="form-group">
          <xsl:variable name="high_filter"
                        select="filters/filter[text()='High'] or contains (filters/keywords/keyword[column='levels']/value, 'h')"/>
          <xsl:variable name="medium_filter"
                        select="filters/filter[text()='Medium'] or contains (filters/keywords/keyword[column='levels']/value, 'm')"/>
          <xsl:variable name="low_filter"
                        select="filters/filter[text()='Low'] or contains (filters/keywords/keyword[column='levels']/value, 'l')"/>
          <xsl:variable name="log_filter"
                        select="filters/filter[text()='Log'] or contains (filters/keywords/keyword[column='levels']/value, 'g')"/>
          <xsl:variable name="false_positive_filter"
                        select="filters/filter[text()='False Postive'] or contains (filters/keywords/keyword[column='levels']/value, 'f')"/>
          <label class="col-2 control-label">
            <xsl:value-of select="gsa:i18n ('Severity (Class)')"/>:
          </label>
          <div class="col-10">
            <label class="checkbox-inline">
              <xsl:choose>
                <xsl:when test="$high_filter">
                  <input type="checkbox" name="level_high" value="1"
                    checked="1"/>
                </xsl:when>
                <xsl:otherwise>
                  <input type="checkbox" name="level_high" value="1"/>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:call-template name="severity-label">
                <xsl:with-param name="level" select="'High'"/>
              </xsl:call-template>
            </label>
            <label class="checkbox-inline">
              <xsl:choose>
                <xsl:when test="$medium_filter">
                  <input type="checkbox" name="level_medium" value="1"
                    checked="1"/>
                </xsl:when>
                <xsl:otherwise>
                  <input type="checkbox" name="level_medium" value="1"/>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:call-template name="severity-label">
                <xsl:with-param name="level" select="'Medium'"/>
              </xsl:call-template>
            </label>
            <label class="checkbox-inline">
              <xsl:choose>
                <xsl:when test="$low_filter">
                  <input type="checkbox" name="level_low" value="1"
                    checked="1"/>
                </xsl:when>
                <xsl:otherwise>
                  <input type="checkbox" name="level_low" value="1"/>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:call-template name="severity-label">
                <xsl:with-param name="level" select="'Low'"/>
              </xsl:call-template>
            </label>
            <label class="checkbox-inline">
              <xsl:choose>
                <xsl:when test="$log_filter">
                  <input type="checkbox" name="level_log" value="1"
                    checked="1"/>
                </xsl:when>
                <xsl:otherwise>
                  <input type="checkbox" name="level_log" value="1"/>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:call-template name="severity-label">
                <xsl:with-param name="level" select="'Log'"/>
              </xsl:call-template>
            </label>
            <label class="checkbox-inline">
              <xsl:choose>
                <xsl:when test="$false_positive_filter">
                  <input type="checkbox"
                    name="level_false_positive"
                    value="1"
                    checked="1"/>
                </xsl:when>
                <xsl:otherwise>
                  <input type="checkbox"
                    name="level_false_positive"
                    value="1"/>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:call-template name="severity-label">
                <xsl:with-param name="level" select="'False Positive'"/>
              </xsl:call-template>
            </label>
          </div>
        </div>
      </xsl:if>
      <xsl:if test="filters/keywords/keyword[column='first'] or $filter_options_nodes/option[text()='first']">
        <xsl:variable name="first_param_name">
          <xsl:choose>
            <xsl:when test="$type = 'report_result'">first_result</xsl:when>
            <xsl:otherwise>first</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <div class="form-group">
          <label for="{$first_param_name}" class="col-2 control-label">
            <xsl:value-of select="gsa:i18n ('First result')"/>:
          </label>
          <div class="col-4">
            <input type="number" name="{$first_param_name}" size="5"
              class="form-control spinner"
              min="1"
              max="{$max}"
              data-type="int"
              value="{filters/keywords/keyword[column='first']/value}"
              maxlength="400"/>
          </div>
        </div>
      </xsl:if>
      <xsl:if test="filters/keywords/keyword[column='rows'] or $filter_options_nodes/option[text()='rows']">
        <xsl:variable name="max_param_name">
          <xsl:choose>
            <xsl:when test="$type = 'report_result'">max_results</xsl:when>
            <xsl:otherwise>max</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <div class="form-group">
          <label for="{$max_param_name}" class="col-2 control-label">
            <xsl:value-of select="gsa:i18n ('Results per page')"/>:
          </label>
          <div class="col-4">
            <input name="{$max_param_name}" size="5"
              class="form-control spinner"
              min="1"
              type="number"
              data-type="int"
              value="{filters/keywords/keyword[column='rows']/value}"
              maxlength="400"/>
          </div>
        </div>
      </xsl:if>
      <xsl:if test="exslt:node-set ($columns)">
        <div class="form-group">
          <label for="sort_field" class="col-2 control-label"><xsl:value-of select="gsa:i18n ('Sort by')"/>:</label>
          <div class="col-10">
            <xsl:variable name="sort" select="sort/field/text ()"/>
            <div class="form-item">
              <select name="sort_field" size="1">
                <xsl:for-each select="exslt:node-set ($columns)/column">
                  <xsl:variable name="single" select="count (column) = 0"/>
                  <xsl:choose>
                    <xsl:when test="boolean (hide_in_filter)"/>
                    <xsl:when test="($single) and ((boolean (field) and field = $sort) or (gsa:column-filter-name (name) = $sort))">
                      <option value="{$sort}" selected="1">
                        <xsl:value-of select="name"/>
                      </option>
                    </xsl:when>
                    <xsl:when test="$single and boolean (field)">
                      <option value="{field}">
                        <xsl:value-of select="name"/>
                      </option>
                    </xsl:when>
                    <xsl:when test="$single">
                      <option value="{gsa:column-filter-name (name)}">
                        <xsl:value-of select="name"/>
                      </option>
                    </xsl:when>
                    <xsl:otherwise>
                      <xsl:for-each select="column">
                        <xsl:choose>
                          <xsl:when test="(boolean (field) and (field = $sort)) or (gsa:column-filter-name (name) = $sort)">
                            <option value="{$sort}" selected="1">
                              <xsl:value-of select="concat(../name, ': ', name)"/>
                            </option>
                          </xsl:when>
                          <xsl:when test="boolean (field)">
                            <option value="{field}">
                              <xsl:value-of select="concat(../name, ': ', name)"/>
                            </option>
                          </xsl:when>
                          <xsl:otherwise>
                            <option value="{gsa:column-filter-name (name)}">
                              <xsl:value-of select="concat(../name, ': ', name)"/>
                            </option>
                          </xsl:otherwise>
                        </xsl:choose>
                      </xsl:for-each>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:for-each>
              </select>
            </div>
            <xsl:variable name="order" select="sort/field/order"/>
            <div class="form-item">
              <label class="radio-inline">
                <xsl:choose>
                  <xsl:when test="$order = 'ascending'">
                    <input type="radio" name="sort_order" value="ascending" checked="1"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <input type="radio" name="sort_order" value="ascending"/>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:value-of select="gsa:i18n ('Ascending')"/>
              </label>
              <label class="radio-inline">
                <xsl:choose>
                  <xsl:when test="$order = 'descending'">
                    <input type="radio" name="sort_order" value="descending" checked="1"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <input type="radio" name="sort_order" value="descending"/>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:value-of select="gsa:i18n ('Descending')"/>
              </label>
            </div>
          </div>
        </div>
      </xsl:if>
    </form>
  </div>
</xsl:template>

<xsl:template name="edit-header-icons">
  <xsl:param name="type"/>
  <xsl:param name="cap-type"/>
  <xsl:param name="cap-type-plural" select="concat ($cap-type, 's')"/>
  <xsl:param name="id"/>
  <!-- i18n with concat : see dynamic_strings.xsl - type-edit -->
  <xsl:variable name="help_url">
    <xsl:choose>
      <xsl:when test="$type = 'config'">
        <xsl:value-of select="concat ('/help/config_editor.html?token=', /envelope/token)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat ('/help/', $type, 's.html?token=', /envelope/token, '#edit_', $type)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <a href="{$help_url}" title="{gsa:i18n ('Help')}: {gsa:i18n (concat ('Edit ', $cap-type))}"
    class="icon icon-sm">
    <img src="/img/help.svg"/>
  </a>
  <!-- dynamic i18n : see dynamic_strings.xsl - type-name-plural -->
  <a href="/omp?cmd=get_{$type}s&amp;filter={str:encode-uri (gsa:envelope-filter (), true ())}&amp;filt_id={/envelope/params/filt_id}&amp;token={/envelope/token}"
     title="{gsa:i18n ($cap-type-plural)}" class="icon icon-sm">
    <img src="/img/list.svg" alt="{gsa:i18n ($cap-type-plural)}"/>
  </a>
  <!-- i18n with concat : see dynamic_strings.xsl - type-name-details -->
  <div class="small_inline_form" style="display: inline; margin-left: 15px; font-weight: normal;">
      <a href="/omp?cmd=get_{$type}&amp;{$type}_id={$id}&amp;filter={str:encode-uri (gsa:envelope-filter (), true ())}&amp;filt_id={/envelope/params/filt_id}&amp;token={/envelope/token}"
        class="icon icon-sm"
        title="{gsa:i18n (concat ($cap-type, ' Details'))}">
      <img src="/img/details.svg" alt="{gsa:i18n ('Details')}"/>
    </a>
  </div>
</xsl:template>

<xsl:template name="get-settings-resource">
  <xsl:param name="id"/>
  <xsl:param name="type"/>
  <xsl:param name="cap_type" select="gsa:capitalise ($type)"/>
  <xsl:param name="resources"/>

  <xsl:choose>
    <xsl:when test="$id">
      <!-- i18n with concat : see dynamic_strings.xsl - type-name-details -->
      <a href="/omp?cmd=get_{$type}&amp;{$type}_id={$id}&amp;token={/envelope/token}"
         title="{gsa:i18n (concat ($cap_type, ' Details'), $type)}">
        <xsl:value-of select="$resources[@id=$id]/name"/>
      </a>
    </xsl:when>
    <xsl:otherwise>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="get-settings-filter">
  <xsl:param name="filter"/>

  <xsl:choose>
    <xsl:when test="$filter">
      <a href="/omp?cmd=get_filter&amp;filter_id={$filter}&amp;token={/envelope/token}"
         title="{gsa:i18n ('Filter Details')}">
        <xsl:value-of select="commands_response/get_filters_response/filter[@id=$filter]/name"/>
      </a>
    </xsl:when>
    <xsl:otherwise>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="edit-settings-resource">
  <xsl:param name="setting"/>
  <xsl:param name="param_name" select="concat('settings_default:', $setting)"/>
  <xsl:param name="resources"/>
  <xsl:param name="selected_id" select="@id"/>

  <select style="margin-bottom: 0px;" name="{$param_name}" class="setting-control" data-setting="{$setting}">
    <option value="">--</option>
    <xsl:for-each select="$resources">
      <xsl:choose>
        <xsl:when test="@id = $selected_id">
          <option value="{@id}" selected="1"><xsl:value-of select="name"/></option>
        </xsl:when>
        <xsl:otherwise>
          <option value="{@id}"><xsl:value-of select="name"/></option>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </select>
</xsl:template>

<xsl:template name="edit-settings-filters">
  <xsl:param name="uuid"/>
  <xsl:param name="filter-type"/>
  <xsl:param name="filter"/>
  <select style="margin-bottom: 0px;" name="settings_filter:{$uuid}" class="setting-control" data-setting="{$uuid}">
    <option value="">--</option>
    <xsl:variable name="id" select="filters/@id"/>
    <xsl:for-each select="commands_response/get_filters_response/filter[type=$filter-type or type='']">
      <xsl:choose>
        <xsl:when test="@id = $filter">
          <option value="{@id}" selected="1"><xsl:value-of select="name"/></option>
        </xsl:when>
        <xsl:otherwise>
          <option value="{@id}"><xsl:value-of select="name"/></option>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:for-each>
  </select>
</xsl:template>

<xsl:template name="severity-settings-list">
  <xsl:param name="default"/>
  <select style="margin-bottom: 0px;" name="severity_class" class="setting-control" data-setting="severity_class">
    <xsl:call-template name="opt">
      <xsl:with-param name="value" select="'nist'"/>
      <xsl:with-param name="content" select="'NVD Vulnerability Severity Ratings'"/>
      <xsl:with-param name="select-value" select="$default"/>
    </xsl:call-template>
    <xsl:call-template name="opt">
      <xsl:with-param name="value" select="'bsi'"/>
      <xsl:with-param name="content" select="'BSI Schwachstellenampel (Germany)'"/>
      <xsl:with-param name="select-value" select="$default"/>
    </xsl:call-template>
    <xsl:call-template name="opt">
      <xsl:with-param name="value" select="'classic'"/>
      <xsl:with-param name="content" select="'OpenVAS Classic'"/>
      <xsl:with-param name="select-value" select="$default"/>
    </xsl:call-template>
    <xsl:call-template name="opt">
      <xsl:with-param name="value" select="'pci-dss'"/>
      <xsl:with-param name="content" select="'PCI-DSS'"/>
      <xsl:with-param name="select-value" select="$default"/>
    </xsl:call-template>
  </select>
</xsl:template>

<xsl:template name="severity-settings-name">
  <xsl:param name="type"/>
  <xsl:choose>
    <xsl:when test="$type = 'nist'">NVD Vulnerability Severity Ratings</xsl:when>
    <xsl:when test="$type = 'bsi'">BSI Schwachstellenampel (Germany)</xsl:when>
    <xsl:when test="$type = 'classic'">OpenVAS Classic</xsl:when>
    <xsl:when test="$type = 'pci-dss'">PCI-DSS</xsl:when>
  </xsl:choose>
</xsl:template>

<xsl:template name="list-window-line-icons">
  <xsl:param name="resource" select="."/>
  <xsl:param name="type"/>
  <xsl:param name="cap-type"/>

  <xsl:param name="id"/>
  <xsl:param name="noedit"/>
  <xsl:param name="noclone"/>
  <xsl:param name="grey-clone"/>
  <xsl:param name="noexport"/>
  <xsl:param name="notrash"/>
  <xsl:param name="params" select="''"/>
  <xsl:param name="next" select="concat ('get_', $type, 's')"/>
  <xsl:param name="next_type" select="''"/>
  <xsl:param name="next_id" select="''"/>
  <xsl:param name="edit-dialog-width" select="'800'"/>
  <xsl:param name="edit-dialog-height" select="'auto'"/>

  <xsl:variable name="next_params_string">
    <xsl:choose>
      <xsl:when test="$next_type != '' and $next_id != ''">
        <xsl:value-of select="concat ('&amp;next_type=', $next_type, '&amp;next_id=', $next_id)"/>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
  </xsl:variable>

  <xsl:choose>
    <xsl:when test="$notrash">
    </xsl:when>
    <xsl:when test="gsa:may (concat ('delete_', $type)) and $resource/writable!='0' and $resource/in_use='0'">
      <xsl:call-template name="trashcan-icon">
        <xsl:with-param name="type" select="$type"/>
        <xsl:with-param name="id" select="$resource/@id"/>
        <xsl:with-param name="params">
          <input type="hidden" name="filter" value="{gsa:envelope-filter ()}"/>
          <input type="hidden" name="filt_id" value="{/envelope/params/filt_id}"/>
          <xsl:if test="$next != ''">
            <input type="hidden" name="next" value="{$next}"/>
          </xsl:if>
          <xsl:if test="$next_id != '' and $next_type != ''">
            <input type="hidden" name="{$next_type}_id" value="{$next_id}"/>
          </xsl:if>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:variable name="inactive_text">
        <!-- i18n with concat : see dynamic_strings.xsl - type-action-denied -->
        <xsl:choose>
          <xsl:when test="$resource/in_use != '0'">
            <xsl:value-of select="gsa:i18n (concat ($cap-type, ' is still in use'))"/>
          </xsl:when>
          <xsl:when test="$resource/writable = '0'">
            <xsl:value-of select="gsa:i18n (concat ($cap-type, ' is not writable'))"/>
          </xsl:when>
          <xsl:when test="not(gsa:may (concat ('delete_', $type)))">
            <xsl:value-of select="gsa:i18n (concat ('Permission to move ', $cap-type, ' to trashcan denied'))"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="gsa:i18n ('Cannot move to trashcan.')"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>
      <img src="/img/trashcan_inactive.svg" class="icon icon-sm"
           alt="{gsa:i18n ('To Trashcan', 'Action Verb')}"
           title="{$inactive_text}"/>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:choose>
    <xsl:when test="$noedit">
    </xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="gsa:may (concat ('modify_', $type)) and $resource/writable!='0'">
          <!-- i18n with concat : see dynamic_strings.xsl - type-edit -->
          <a href="/omp?cmd=edit_{$type}&amp;{$type}_id={$resource/@id}&amp;next={$next}{$next_params_string}{$params}&amp;filter={str:encode-uri (gsa:envelope-filter (), true ())}&amp;filt_id={/envelope/params/filt_id}&amp;token={/envelope/token}"
             title="{gsa:i18n (concat ('Edit ', $cap-type))}"
             class="edit-action-icon icon icon-sm"
             data-type="{$type}" data-id="{$resource/@id}"
             data-height="{$edit-dialog-height}" data-width="{$edit-dialog-width}"
             data-reload="window">
            <img src="/img/edit.svg" alt="{gsa:i18n ('Edit', 'Action Verb')}"/>
          </a>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="inactive_text">
            <!-- i18n with concat : see dynamic_strings.xsl - type-action-denied -->
            <xsl:choose>
              <xsl:when test="$resource/writable = '0'">
                <xsl:value-of select="gsa:i18n (concat ($cap-type, ' is not writable'))"/>
              </xsl:when>
              <xsl:when test="not(gsa:may (concat ('modify_', $type)))">
                <xsl:value-of select="gsa:i18n (concat ('Permission to edit ', $cap-type, ' denied'))"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="gsa:i18n (concat ('Cannot modify ', $cap-type))"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <img src="/img/edit_inactive.svg" alt="{gsa:i18n ('Edit', 'Action Verb')}"
            title="{$inactive_text}" class="icon icon-sm"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:choose>
    <xsl:when test="$noclone">
    </xsl:when>
    <xsl:when test="$grey-clone">
      <!-- i18n with concat : see dynamic_strings.xsl - type-action-denied -->
      <img src="/img/clone_inactive.svg"
           alt="{gsa:i18n ('Clone', 'Action Verb')}"
           value="Clone" class="icon icon-sm"
           title="{gsa:i18n (concat ($cap-type, ' may not be cloned'))}"/>
    </xsl:when>
    <xsl:when test="gsa:may-clone ($type)">
      <div class="icon icon-sm">
        <form action="/omp" method="post" enctype="multipart/form-data">
          <input type="hidden" name="token" value="{/envelope/token}"/>
          <input type="hidden" name="caller" value="{/envelope/current_page}"/>
          <input type="hidden" name="cmd" value="clone"/>
          <input type="hidden" name="resource_type" value="{$type}"/>
          <input type="hidden" name="next" value="get_{$type}"/>
          <input type="hidden" name="id" value="{$resource/@id}"/>
          <input type="hidden" name="filter" value="{gsa:envelope-filter ()}"/>
          <input type="hidden" name="filt_id" value="{/envelope/params/filt_id}"/>
          <input type="image" src="/img/clone.svg" alt="{gsa:i18n ('Clone', 'Action Verb')}"
                 name="Clone" value="Clone" title="{gsa:i18n ('Clone', 'Action Verb')}"/>
        </form>
      </div>
    </xsl:when>
    <xsl:when test="$resource/owner/name = /envelope/login/text() or string-length ($resource/owner/name) = 0">
      <!-- i18n with concat : see dynamic_strings.xsl - type-action-denied -->
      <img src="/img/clone_inactive.svg"
           alt="{gsa:i18n ('Clone', 'Action Verb')}"
           value="Clone" class="icon icon-sm"
           title="{gsa:i18n (concat ($cap-type, ' must be owned or global'))}"/>
    </xsl:when>
    <xsl:otherwise>
      <img src="/img/clone_inactive.svg"
           alt="{gsa:i18n ('Clone', 'Action Verb')}"
           value="Clone" class="icon icon-sm"
           title="{gsa:i18n ('Permission to clone denied')}"/>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:choose>
    <xsl:when test="$noexport">
    </xsl:when>
    <xsl:otherwise>
      <!-- i18n with concat : see dynamic_strings.xsl - type-export -->
      <a href="/omp?cmd=export_{$type}&amp;{$type}_id={$resource/@id}&amp;next={$next}{$params}&amp;filter={str:encode-uri (gsa:envelope-filter (), true ())}&amp;filt_id={/envelope/params/filt_id}&amp;token={/envelope/token}"
        class="icon icon-sm"
        title="{gsa:i18n (concat ('Export ', $cap-type))}">
        <img src="/img/download.svg" alt="{gsa:i18n ('Export', 'Action Verb')}"/>
      </a>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="trash-delete-icon">
  <xsl:param name="type"></xsl:param>
  <xsl:param name="id"></xsl:param>
  <xsl:param name="params"></xsl:param>

  <div class="icon icon-sm">
    <form action="/omp" method="post" enctype="multipart/form-data">
      <input type="hidden" name="token" value="{/envelope/token}"/>
      <input type="hidden" name="caller" value="{/envelope/current_page}"/>
      <input type="hidden" name="cmd" value="delete_trash_{$type}"/>
      <input type="hidden" name="next" value="get_trash"/>
      <input type="hidden" name="{$type}_id" value="{$id}"/>
      <input type="image" src="/img/delete.svg" alt="{gsa:i18n ('Delete')}"
             name="Delete" value="Delete" title="{gsa:i18n ('Delete')}"/>
      <xsl:copy-of select="$params"/>
    </form>
  </div>
</xsl:template>

<xsl:template name="delete-icon">
  <xsl:param name="type"></xsl:param>
  <xsl:param name="id"></xsl:param>
  <xsl:param name="params"></xsl:param>

  <div class="icon icon-sm">
    <xsl:choose>
      <xsl:when test="$type = 'user'">
        <form action="/omp" method="get" enctype="multipart/form-data">
          <input type="hidden" name="token" value="{/envelope/token}"/>
          <input type="hidden" name="caller" value="{/envelope/current_page}"/>
          <input type="hidden" name="cmd" value="delete_{$type}_confirm"/>
          <input type="hidden" name="{$type}_id" value="{$id}"/>
          <input type="image" src="/img/delete.svg" alt="{gsa:i18n ('Delete')}"
            class="delete-action-icon" data-reload="next" data-type="{$type}" data-id="{$id}"
            name="Delete" value="Delete" title="{gsa:i18n ('Delete')}"/>
          <xsl:copy-of select="$params"/>
        </form>
      </xsl:when>
      <xsl:otherwise>
        <form style="display: inline; font-size: 0px;" action="/omp" method="post" enctype="multipart/form-data">
          <input type="hidden" name="token" value="{/envelope/token}"/>
          <input type="hidden" name="caller" value="{/envelope/current_page}"/>
          <input type="hidden" name="cmd" value="delete_{$type}"/>
          <input type="hidden" name="{$type}_id" value="{$id}"/>
          <input type="image" src="/img/delete.svg" alt="{gsa:i18n ('Delete')}"
                name="Delete" value="Delete" title="{gsa:i18n ('Delete')}"/>
          <xsl:copy-of select="$params"/>
        </form>
      </xsl:otherwise>
    </xsl:choose>
  </div>
</xsl:template>

<xsl:template name="restore-icon">
  <xsl:param name="id"></xsl:param>

  <xsl:if test="gsa:may-op ('restore')">
    <div class="icon icon-sm">
      <form action="/omp"
            method="post" enctype="multipart/form-data">
        <input type="hidden" name="token" value="{/envelope/token}"/>
        <input type="hidden" name="caller" value="{/envelope/current_page}"/>
        <input type="hidden" name="cmd" value="restore"/>
        <input type="hidden" name="target_id" value="{$id}"/>
        <input type="image" src="/img/restore.svg" alt="{gsa:i18n ('Restore')}"
               name="Restore" value="Restore" title="{gsa:i18n ('Restore')}"/>
      </form>
    </div>
  </xsl:if>
</xsl:template>

<xsl:template name="resume-icon">
  <xsl:param name="type"></xsl:param>
  <xsl:param name="id"></xsl:param>
  <xsl:param name="params"></xsl:param>
  <xsl:param name="cmd">resume_<xsl:value-of select="type"/></xsl:param>

  <div class="icon icon-sm">
    <form action="/omp" method="post" enctype="multipart/form-data">
      <input type="hidden" name="token" value="{/envelope/token}"/>
      <input type="hidden" name="caller" value="{/envelope/current_page}"/>
      <input type="hidden" name="cmd" value="{$cmd}"/>
      <input type="hidden" name="{$type}_id" value="{$id}"/>
      <input type="image" src="/img/resume.svg" alt="{gsa:i18n ('Resume')}"
             name="Resume" value="Resume" title="{gsa:i18n ('Resume')}"/>
      <xsl:copy-of select="$params"/>
    </form>
  </div>
</xsl:template>

<xsl:template name="start-icon">
  <xsl:param name="type"></xsl:param>
  <xsl:param name="id"></xsl:param>
  <xsl:param name="params"></xsl:param>
  <xsl:param name="cmd">start_<xsl:value-of select="$type"/></xsl:param>
  <xsl:param name="alt"><xsl:value-of select="gsa:i18n('Start', 'Action Verb')"/></xsl:param>
  <xsl:param name="name">Start</xsl:param>

  <div class="icon icon-sm">
    <form action="/omp" method="post" enctype="multipart/form-data">
      <input type="hidden" name="token" value="{/envelope/token}"/>
      <input type="hidden" name="caller" value="{/envelope/current_page}"/>
      <input type="hidden" name="cmd" value="{$cmd}"/>
      <input type="hidden" name="{$type}_id" value="{$id}"/>
      <input type="hidden" name="filter" value="{gsa:envelope-filter ()}"/>
      <input type="hidden" name="filt_id" value="{/envelope/params/filt_id}"/>
      <input type="image" src="/img/start.svg" alt="{$alt}"
             name="{$name}" value="{$name}" title="{$alt}"/>
      <xsl:copy-of select="$params"/>
    </form>
  </div>
</xsl:template>

<xsl:template name="stop-icon">
  <xsl:param name="type"></xsl:param>
  <xsl:param name="id"></xsl:param>
  <xsl:param name="params"></xsl:param>

  <div class="icon icon-sm">
    <form action="/omp" method="post" enctype="multipart/form-data">
      <input type="hidden" name="token" value="{/envelope/token}"/>
      <input type="hidden" name="caller" value="{/envelope/current_page}"/>
      <input type="hidden" name="cmd" value="stop_{$type}"/>
      <input type="hidden" name="{$type}_id" value="{$id}"/>
      <input type="image" src="/img/stop.svg" alt="{gsa:i18n('Stop', 'Action Verb')}"
             name="Stop" value="Stop" title="{gsa:i18n('Stop', 'Action Verb')}"/>
      <xsl:copy-of select="$params"/>
    </form>
  </div>
</xsl:template>

<xsl:template name="trashcan-icon">
  <xsl:param name="type"></xsl:param>
  <xsl:param name="id"></xsl:param>
  <xsl:param name="fragment"></xsl:param>
  <xsl:param name="params"></xsl:param>

  <div class="icon icon-sm ajax-post" data-reload="next" data-busy-text="{gsa:i18n ('Moving to trashcan...')}">
    <img src="/img/trashcan.svg" alt="{gsa:i18n ('To Trashcan', 'Action Verb')}"
      name="To Trashcan" title="{gsa:i18n ('Move To Trashcan', 'Action Verb')}"/>
    <form action="/omp{$fragment}" method="post" enctype="multipart/form-data">
      <input type="hidden" name="token" value="{/envelope/token}"/>
      <input type="hidden" name="caller" value="{/envelope/current_page}"/>
      <input type="hidden" name="cmd" value="delete_{$type}"/>
      <input type="hidden" name="{$type}_id" value="{$id}"/>
      <xsl:copy-of select="$params"/>
    </form>
  </div>
</xsl:template>

<xsl:template name="highlight-diff">
  <xsl:param name="string"></xsl:param>

  <xsl:for-each select="str:tokenize($string, '&#10;')">
    <xsl:call-template name="highlight-diff-line">
      <xsl:with-param name="string"><xsl:value-of select="."/></xsl:with-param>
      <xsl:with-param name="class-string">
        <xsl:choose>
          <xsl:when test="(substring (., 1, 1) = '\') and preceding-sibling::*">
            <!-- Use class from previous line for one like
                 "\ No newline at end of file" -->
            <xsl:value-of select="preceding-sibling::*[1]"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="."/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:with-param>
    </xsl:call-template>
  </xsl:for-each>
</xsl:template>

<!-- This is called within a PRE. -->
<xsl:template name="break-diff-line">
  <xsl:param name="string"></xsl:param>
  <xsl:param name="break-length" select="90"/>
  <xsl:choose>
    <xsl:when test="string-length ($string) &gt; $break-length">
      <xsl:value-of select="substring ($string, 1, $break-length)"/>
      <xsl:text>&#8629;&#10;</xsl:text>
      <xsl:call-template name="break-diff-line">
        <xsl:with-param name="string" select="substring ($string, $break-length+1, string-length ($string))"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$string"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- This is called within a PRE. -->
<xsl:template name="highlight-diff-line">
  <xsl:param name="string"></xsl:param>
  <!-- class-string : String to base class on (e.g. for \ ... lines) -->
  <xsl:param name="class-string" select="$string"/>
  <xsl:choose>
    <xsl:when test="string-length($string) = 0">
      <!-- The string is empty. -->
    </xsl:when>
    <xsl:when test="(substring($class-string, 1, 1) = '@')">
      <div class="diff-line-hunk">
        <xsl:call-template name="break-diff-line">
          <xsl:with-param name="string" select="$string"/>
        </xsl:call-template>
      </div>
    </xsl:when>
    <xsl:when test="(substring($class-string, 1, 1) = '+')">
      <div class="diff-line-plus">
        <xsl:call-template name="break-diff-line">
          <xsl:with-param name="string" select="$string"/>
        </xsl:call-template>
      </div>
    </xsl:when>
    <xsl:when test="(substring($class-string, 1, 1) = '-')">
      <div class="diff-line-minus">
        <xsl:call-template name="break-diff-line">
          <xsl:with-param name="string" select="$string"/>
        </xsl:call-template>
      </div>
    </xsl:when>
    <xsl:otherwise>
      <div class="diff-line">
        <xsl:call-template name="break-diff-line">
          <xsl:with-param name="string" select="$string"/>
        </xsl:call-template>
      </div>
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>

<xsl:template name="severity-bar">
  <xsl:param name="extra_text"></xsl:param>
  <xsl:param name="notext"></xsl:param>
  <xsl:param name="cvss"></xsl:param>
  <xsl:param name="threat"><xsl:value-of select="gsa:cvss-risk-factor($cvss)"/></xsl:param>
  <xsl:param name="title"><xsl:value-of select="gsa:i18n($threat, 'Severity')"/></xsl:param>
  <xsl:param name="scale">10</xsl:param>

  <xsl:variable name="fill">
    <xsl:value-of select="number($cvss) * $scale"/>
  </xsl:variable>
  <xsl:variable name="width"><xsl:value-of select="10 * $scale"/></xsl:variable>
  <div class="progressbar_box" title="{$title}" style="width:{$width}px;">
    <xsl:choose>
      <xsl:when test="$threat = 'None'">
        <div class="progressbar_bar_done" style="width:0px;"></div>
      </xsl:when>
      <xsl:when test="$threat = 'Log'">
        <div class="progressbar_bar_gray" style="width:{$fill}px;"></div>
      </xsl:when>
      <xsl:when test="$threat = 'Low'">
        <div class="progressbar_bar_done" style="width:{$fill}px;"></div>
      </xsl:when>
      <xsl:when test="$threat = 'Medium'">
        <div class="progressbar_bar_request" style="width:{$fill}px;"></div>
      </xsl:when>
      <xsl:when test="$threat = 'High'">
        <div class="progressbar_bar_error" style="width:{$fill}px;"></div>
      </xsl:when>
    </xsl:choose>
      <div class="progressbar_text">
        <xsl:if test="not($notext)">
          <xsl:value-of select="$cvss"/>
        </xsl:if>
        <xsl:if test="$extra_text">
          <xsl:value-of select="$extra_text"/>
        </xsl:if>
      </div>
  </div>
</xsl:template>

<xsl:template name="severity-label">
  <xsl:param name="level"/>
  <xsl:param name="font-size" select="'9'"/>
  <xsl:param name="width" select="floor($font-size * 6.0)"/>
  <xsl:choose>
    <xsl:when test="$level = 'High'">
      <div class="label_high" style="font-size:{$font-size}px; min-width:{$width}px"><xsl:value-of select="gsa:i18n ('High', 'Severity')"/></div>
    </xsl:when>
    <xsl:when test="$level = 'Medium'">
      <div class="label_medium" style="font-size:{$font-size}px; min-width:{$width}px"><xsl:value-of select="gsa:i18n ('Medium', 'Severity')"/></div>
    </xsl:when>
    <xsl:when test="$level = 'Low'">
      <div class="label_low" style="font-size:{$font-size}px; min-width:{$width}px"><xsl:value-of select="gsa:i18n ('Low', 'Severity')"/></div>
    </xsl:when>
    <xsl:when test="$level = 'Log'">
      <div class="label_log" style="font-size:{$font-size}px; min-width:{$width}px"><xsl:value-of select="gsa:i18n ('Log', 'Severity')"/></div>
    </xsl:when>
    <xsl:when test="$level = 'False Positive' or $level = 'False&#xa0;Positive'">
      <div class="label_none" style="font-size:{$font-size}px; min-width:{$width}px"><xsl:value-of select="gsa:i18n ('False Pos.', 'Severity')"/></div>
    </xsl:when>
    <xsl:otherwise>
      <div class="label_none" style="font-size:{$font-size}px; min-width:{$width}px"><xsl:value-of select="$level"/></div>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="build-levels">
  <xsl:param name="filters"></xsl:param>
  <xsl:for-each select="$filters">
    <xsl:choose>
      <xsl:when test="text()='High'">h</xsl:when>
      <xsl:when test="text()='Medium'">m</xsl:when>
      <xsl:when test="text()='Low'">l</xsl:when>
      <xsl:when test="text()='Log'">g</xsl:when>
      <xsl:when test="text()='False Positive'">f</xsl:when>
    </xsl:choose>
  </xsl:for-each>
</xsl:template>

<xsl:template name="scanner-type-name">
  <xsl:param name="type"/>
  <xsl:choose>
    <xsl:when test="$type = '1'">OSP Scanner</xsl:when>
    <xsl:when test="$type = '2'">OpenVAS Scanner</xsl:when>
    <xsl:when test="$type = '3'">CVE Scanner</xsl:when>
    <xsl:when test="$type = '4'">GMP Slave</xsl:when>
    <xsl:otherwise>Unknown type (<xsl:value-of select="type"/>)</xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="scanner-type-list">
  <xsl:param name="default"/>
  <xsl:call-template name="opt">
    <xsl:with-param name="value" select="4"/>
    <xsl:with-param name="content" select="'GMP Slave'"/>
    <xsl:with-param name="select-value" select="$default"/>
  </xsl:call-template>
  <xsl:call-template name="opt">
    <xsl:with-param name="value" select="2"/>
    <xsl:with-param name="content" select="'OpenVAS Scanner'"/>
    <xsl:with-param name="select-value" select="$default"/>
  </xsl:call-template>
  <xsl:call-template name="opt">
    <xsl:with-param name="value" select="1"/>
    <xsl:with-param name="content" select="'OSP Scanner'"/>
    <xsl:with-param name="select-value" select="$default"/>
  </xsl:call-template>
</xsl:template>

<xsl:template name="solution-icon">
  <xsl:param name="solution_type" select="''"/>
  <xsl:choose>
    <xsl:when test="$solution_type = ''">
    </xsl:when>
    <xsl:when test="$solution_type = 'Workaround'">
      <img class="icon icon-sm" src="/img/st_workaround.svg" title="{$solution_type}" alt="{$solution_type}"/>
    </xsl:when>
    <xsl:when test="$solution_type = 'Mitigation'">
      <img class="icon icon-sm" src="/img/st_mitigate.svg" title="{$solution_type}" alt="{$solution_type}"/>
    </xsl:when>
    <xsl:when test="$solution_type = 'VendorFix'">
      <img class="icon icon-sm" src="/img/st_vendorfix.svg" title="{$solution_type}" alt="{$solution_type}"/>
    </xsl:when>
    <xsl:when test="$solution_type = 'NoneAvailable'">
      <img class="icon icon-sm" src="/img/st_nonavailable.svg" title="{$solution_type}" alt="{$solution_type}"/>
    </xsl:when>
    <xsl:when test="$solution_type = 'WillNotFix'">
      <img class="icon icon-sm" src="/img/st_willnotfix.svg" title="{$solution_type}" alt="{$solution_type}"/>
    </xsl:when>
    <xsl:otherwise>
      <img class="icon icon-sm" src="/img/os_unknown.svg" title="{$solution_type}" alt="{$solution_type}"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- GENERAL ERROR MESSAGES -->

<xsl:template match="action_status">
  <xsl:call-template name="command_result_dialog">
    <xsl:with-param name="operation" select="../prev_action"/>
    <xsl:with-param name="status" select="text()"/>
    <xsl:with-param name="msg" select="../action_message"/>
  </xsl:call-template>
</xsl:template>

<!-- BEGIN GENERAL TAGS VIEWS -->

<xsl:template name="user-tags-window-checked">
  <xsl:param name="resource_type"/>
  <xsl:param name="resource_subtype"/>
  <xsl:param name="resource_id"/>
  <xsl:param name="next"/>
  <xsl:param name="report_section"/>
  <xsl:param name="user_tags"/>
  <xsl:param name="tag_names"/>

  <div class="section-header">
    <a href="#" class="icon icon-sm icon-action toggle-action-icon"
      data-target="#usertags-box" data-name="User Tags" data-variable="usertags-box--collapsed">
      <img src="/img/fold.svg"/>
    </a>
    <a href="/help/user-tags.html?token={/envelope/token}"
       class="icon icon-sm icon-action"
       title="{gsa:i18n ('Help')}: {gsa:i18n ('User Tags list')}">
      <img src="/img/help.svg"/>
    </a>
      <xsl:choose>
        <xsl:when test="not (gsa:may-op ('create_tag'))"/>
        <xsl:when test="$report_section != ''">
          <a href="/omp?cmd=new_tag&amp;resource_id={$resource_id}&amp;resource_type={$resource_type}&amp;next={$next}&amp;next_type={$resource_type}&amp;next_id={$resource_id}&amp;filter={str:encode-uri (gsa:envelope-filter (), true ())}&amp;filt_id={/envelope/params/filt_id}&amp;report_section={$report_section}&amp;token={/envelope/token}"
             title="{gsa:i18n ('New tag')}"
             data-reload="window"
             class="new-action-icon icon icon-sm icon-action" data-type="tag" data-extra="resource_id={$resource_id}&amp;resource_type={$resource_type}">
            <img src="/img/new.svg" alt="{gsa:i18n ('Add tag')}"/>
          </a>
        </xsl:when>
        <xsl:when test="$resource_subtype != ''">
          <a href="/omp?cmd=new_tag&amp;resource_id={$resource_id}&amp;resource_type={$resource_subtype}&amp;next={$next}&amp;next_type={$resource_type}&amp;next_subtype={$resource_subtype}&amp;next_id={$resource_id}&amp;filter={str:encode-uri (gsa:envelope-filter (), true ())}&amp;filt_id={/envelope/params/filt_id}&amp;token={/envelope/token}"
             title="{gsa:i18n ('New Tag')}"
             data-reload="window"
             class="new-action-icon icon icon-sm icon-action" data-type="tag" data-extra="resource_id={$resource_id}&amp;resource_type={$resource_subtype}">
            <img src="/img/new.svg" alt="{gsa:i18n ('Add tag')}"/>
          </a>
        </xsl:when>
        <xsl:otherwise>
          <a href="/omp?cmd=new_tag&amp;resource_id={$resource_id}&amp;resource_type={$resource_type}&amp;next={$next}&amp;next_type={$resource_type}&amp;next_id={$resource_id}&amp;filter={str:encode-uri (gsa:envelope-filter (), true ())}&amp;filt_id={/envelope/params/filt_id}&amp;token={/envelope/token}"
             title="{gsa:i18n ('New Tag')}"
             data-reload="window"
             class="new-action-icon icon icon-sm icon-action" data-type="tag" data-extra="resource_id={$resource_id}&amp;resource_type={$resource_type}">
            <img src="/img/new.svg" alt="{gsa:i18n ('Add tag')}"/>
          </a>
        </xsl:otherwise>
      </xsl:choose>
    <h2>
      <a href="/ng/tags?filter=resource_uuid={$resource_id}"
         title="{gsa:i18n ('Tags')}">
        <img class="icon icon-sm" src="/img/tag.svg" alt="Tags"/>
      </a>
      <xsl:value-of select="gsa:i18n ('User Tags')"/>
      <xsl:choose>
        <xsl:when test="$user_tags/count != 0">
          (<xsl:value-of select="$user_tags/count"/>)
        </xsl:when>
        <xsl:otherwise>
          (<xsl:value-of select="gsa:i18n ('none', 'Tags')"/>)
        </xsl:otherwise>
      </xsl:choose>
    </h2>
  </div>

  <div class="section-box" id="usertags-box">
    <xsl:if test="count(//delete_tag_response[@status!=200]|//modify_tag_response[@status!=200]|//create_tag_response[@status!=201]) = 0">
      <a name="user_tags"/>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="count($tag_names/tag) > 0">
        <div class="ajax-post" data-reload="next" data-button="input.icon" data-busy-text="{gsa:i18n ('Adding Tag...')}">
          <form class="form-inline" action="/omp#user_tags" method="post" enctype="multipart/form-data">
            <input type="hidden" name="comment"/>
            <input type="hidden" name="active" value="1"/>
            <input type="hidden" name="caller" value="{/envelope/current_page}"/>
            <input type="hidden" name="token" value="{/envelope/token}"/>
            <input type="hidden" name="cmd" value="create_tag"/>
            <input type="hidden" name="resource_id" value="{$resource_id}"/>

            <div class="form-group">
              <label class="control-label">
                <b><xsl:value-of select="gsa:i18n ('Add Tag')"/>:</b>
              </label>
              <select style="margin-bottom: 0px;" name="tag_name" size="1">
                <xsl:for-each select="$tag_names/tag">
                  <xsl:call-template name="opt">
                    <xsl:with-param name="value" select="name/text()"/>
                  </xsl:call-template>
                </xsl:for-each>
              </select>
            </div>

            <div class="form-group">
              <label class="control-label">
                <xsl:value-of select="gsa:i18n ('with Value', 'Tag')"/>:
              </label>
              <input type="text" class="form-control" name="tag_value"/>
            </div>
            <div class="form-group">
              <input type="image" src="/img/tag.svg" alt="{gsa:i18n ('Add Tag')}"
                name="Add Tag" value="Add Tag" title="{gsa:i18n ('Add Tag')}"
                class="icon icon-sm"/>
            </div>
            <xsl:choose>
              <xsl:when test="$resource_subtype!=''">
                <input type="hidden" name="resource_type" value="{$resource_subtype}"/>
              </xsl:when>
              <xsl:otherwise>
                <input type="hidden" name="resource_type" value="{$resource_type}"/>
              </xsl:otherwise>
            </xsl:choose>
            <input type="hidden" name="resource_id" value="{$resource_id}"/>
            <input type="hidden" name="next" value="{$next}"/>
            <xsl:choose>
              <xsl:when test="$resource_type='nvt'">
                <input type="hidden"
                        name="oid"
                        value="{$resource_id}"/>
              </xsl:when>
              <xsl:otherwise>
                <input type="hidden"
                        name="{$resource_type}_id"
                        value="{$resource_id}"/>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:if test="$resource_type='info'">
              <input type="hidden"
                    name="details"
                    value="1"/>
            </xsl:if>
            <xsl:if test="$resource_subtype != ''">
              <input type="hidden"
                      name="{$resource_type}_type"
                      value="{$resource_subtype}"/>
            </xsl:if>
            <xsl:if test="$report_section != ''">
              <input type="hidden"
                      name="report_section"
                      value="{$report_section}"/>
            </xsl:if>
          </form>
        </div>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="$user_tags/count != 0">
        <table class="gbntable">
          <tr class="gbntablehead2">
            <td><xsl:value-of select="gsa:i18n ('Name')"/></td>
            <td><xsl:value-of select="gsa:i18n ('Value')"/></td>
            <td><xsl:value-of select="gsa:i18n ('Comment')"/></td>
            <td style="width: {gsa:actions-width (3)}px"><xsl:value-of select="gsa:i18n ('Actions')"/></td>
          </tr>
          <xsl:apply-templates select="$user_tags/tag" mode="for_resource">
            <xsl:with-param name="resource_type" select="$resource_type"/>
            <xsl:with-param name="resource_subtype" select="$resource_subtype"/>
            <xsl:with-param name="resource_id"   select="$resource_id"/>
            <xsl:with-param name="next" select="$next"/>
            <xsl:with-param name="report_section" select="$report_section"/>
          </xsl:apply-templates>
        </table>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>
  </div>
</xsl:template>

<xsl:template name="user-tags-window">
  <xsl:param name="resource_type"/>
  <xsl:param name="resource_subtype"/>
  <xsl:param name="resource_id" select="@id"/>
  <xsl:param name="next" select="concat('get_',$resource_type)"/>
  <xsl:param name="report_section" select="''"/>
  <xsl:param name="user_tags" select="user_tags" />
  <xsl:param name="tag_names" select="../../get_tags_response"/>
  <xsl:if test="gsa:may-op ('get_tags')">
    <xsl:call-template name="user-tags-window-checked">
      <xsl:with-param name="resource_type" select="$resource_type"/>
      <xsl:with-param name="resource_subtype" select="$resource_subtype"/>
      <xsl:with-param name="resource_id" select="$resource_id"/>
      <xsl:with-param name="next" select="$next"/>
      <xsl:with-param name="report_section" select="$report_section"/>
      <xsl:with-param name="user_tags" select="$user_tags"/>
      <xsl:with-param name="tag_names" select="$tag_names"/>
    </xsl:call-template>
  </xsl:if>
</xsl:template>

<xsl:template match="tag" mode="for_resource">
  <xsl:param name="resource_type"/>
  <xsl:param name="resource_subtype"/>
  <xsl:param name="resource_id"/>
  <xsl:param name="next"/>
  <xsl:param name="report_section" select="''"/>

  <tr class="{gsa:table-row-class(position())}">
    <td>
      <a href="/omp?cmd=get_tag&amp;tag_id={@id}&amp;token={/envelope/token}"
          title="{gsa:i18n ('Tag Details')}">
        <xsl:value-of select="name"/>
      </a>
    </td>
    <td><xsl:value-of select="value"/></td>
    <td><xsl:value-of select="comment"/></td>
    <td class="table-actions">

      <xsl:call-template name="toggle-tag-icon">
        <xsl:with-param name="id" select="@id"/>
        <xsl:with-param name="enable" select="0"/>
        <xsl:with-param name="params">
          <input type="hidden" name="next" value="{$next}"/>
          <xsl:choose>
            <xsl:when test="$resource_type='nvt'">
              <input type="hidden" name="oid" value="{$resource_id}"/>
            </xsl:when>
            <xsl:otherwise>
              <input type="hidden" name="{concat($resource_type,'_id')}" value="{$resource_id}"/>
            </xsl:otherwise>
          </xsl:choose>
          <input type="hidden" name="filter" value="{gsa:envelope-filter ()}"/>
          <input type="hidden" name="filt_id" value="{/envelope/params/filt_id}"/>
          <xsl:if test="$resource_subtype != ''">
            <input type="hidden"
                   name="{$resource_type}_type"
                   value="{$resource_subtype}"/>
          </xsl:if>
          <xsl:if test="$resource_type = 'info'">
            <input type="hidden"
                   name="details"
                   value="1"/>
          </xsl:if>
          <xsl:if test="$report_section != ''">
            <input type="hidden"
                    name="report_section"
                    value="{$report_section}"/>
          </xsl:if>
        </xsl:with-param>
        <xsl:with-param name="fragment" select="'#user_tags'"/>
      </xsl:call-template>

      <xsl:call-template name="trashcan-icon">
        <xsl:with-param name="type" select="'tag'"/>
        <xsl:with-param name="id" select="@id"/>
        <xsl:with-param name="params">
          <input type="hidden" name="next" value="{$next}"/>
          <xsl:choose>
            <xsl:when test="$resource_type='nvt'">
              <input type="hidden" name="oid" value="{$resource_id}"/>
            </xsl:when>
            <xsl:otherwise>
              <input type="hidden" name="{concat($resource_type,'_id')}" value="{$resource_id}"/>
            </xsl:otherwise>
          </xsl:choose>
          <input type="hidden" name="filter" value="{gsa:envelope-filter ()}"/>
          <input type="hidden" name="filt_id" value="{/envelope/params/filt_id}"/>
          <xsl:if test="$resource_subtype != ''">
            <input type="hidden"
                   name="{$resource_type}_type"
                   value="{$resource_subtype}"/>
          </xsl:if>
          <xsl:if test="$resource_type = 'info'">
            <input type="hidden"
                   name="details"
                   value="1"/>
          </xsl:if>
          <xsl:if test="$report_section != ''">
            <input type="hidden"
                    name="report_section"
                    value="{$report_section}"/>
          </xsl:if>
        </xsl:with-param>
        <xsl:with-param name="fragment" select="'#user_tags'"/>
      </xsl:call-template>

      <xsl:choose>
        <xsl:when test="$report_section != ''">
          <a href="/omp?cmd=edit_tag&amp;tag_id={@id}&amp;next={$next}&amp;next_type={$resource_type}&amp;next_subtype={$resource_subtype}&amp;next_id={$resource_id}&amp;filter={str:encode-uri (gsa:envelope-filter (), true ())}&amp;filt_id={/envelope/params/filt_id}&amp;report_section={$report_section}&amp;token={/envelope/token}"
             class="edit-action-icon icon icon-sm" data-type="tag" data-id="{@id}"
             title="{gsa:i18n ('Edit Tag')}">
            <img src="/img/edit.svg"/>
          </a>
        </xsl:when>
        <xsl:when test="$resource_subtype!=''">
          <a href="/omp?cmd=edit_tag&amp;tag_id={@id}&amp;next={$next}&amp;next_type={$resource_type}&amp;next_subtype={$resource_subtype}&amp;next_id={$resource_id}&amp;filter={str:encode-uri (gsa:envelope-filter (), true ())}&amp;filt_id={/envelope/params/filt_id}&amp;token={/envelope/token}"
             class="edit-action-icon icon icon-sm" data-type="tag" data-id="{@id}"
             title="{gsa:i18n ('Edit Tag')}">
            <img src="/img/edit.svg"/>
          </a>
        </xsl:when>
        <xsl:otherwise>
          <a href="/omp?cmd=edit_tag&amp;tag_id={@id}&amp;next={$next}&amp;next_type={$resource_type}&amp;next_subtype={$resource_subtype}&amp;next_id={$resource_id}&amp;filter={str:encode-uri (gsa:envelope-filter (), true ())}&amp;filt_id={/envelope/params/filt_id}&amp;token={/envelope/token}"
             class="edit-action-icon icon icon-sm" data-type="tag" data-id="{@id}"
             title="{gsa:i18n ('Edit Tag')}">
            <img src="/img/edit.svg"/>
          </a>
        </xsl:otherwise>
      </xsl:choose>
    </td>
  </tr>
</xsl:template>

<xsl:template name="toggle-tag-icon">
  <xsl:param name="id"></xsl:param>
  <xsl:param name="enable"></xsl:param>
  <xsl:param name="fragment"></xsl:param>
  <xsl:param name="params"></xsl:param>

  <xsl:if test="gsa:may-op ('modify_tag')">
    <div class="icon icon-sm ajax-post" data-reload="next" data-busy-text="{gsa:i18n ('Toggling Tag...')}">
      <xsl:choose>
        <xsl:when test="$enable">
          <img src="/img/enable.svg" alt="{gsa:i18n ('Enable Tag')}"
            name="Enable Tag" title="{gsa:i18n ('Enable Tag')}"/>
        </xsl:when>
        <xsl:otherwise>
          <img src="/img/disable.svg" alt="{gsa:i18n ('Disable Tag')}"
            name="Disable Tag" title="{gsa:i18n ('Disable Tag')}"/>
        </xsl:otherwise>
      </xsl:choose>
      <form action="/omp{$fragment}" method="post" enctype="multipart/form-data">
        <input type="hidden" name="token" value="{/envelope/token}"/>
        <input type="hidden" name="caller" value="{/envelope/current_page}"/>
        <input type="hidden" name="cmd" value="toggle_tag"/>
        <input type="hidden" name="enable" value="{$enable}"/>
        <input type="hidden" name="tag_id" value="{$id}"/>
        <xsl:copy-of select="$params"/>
      </form>
    </div>
  </xsl:if>
</xsl:template>

<xsl:template name="user_tag_list">
  <xsl:param name="user_tags" select="user_tags" />
  <xsl:for-each select="user_tags/tag">
    <a href="/omp?cmd=get_tag&amp;tag_id={@id}&amp;token={/envelope/token}">
      <xsl:value-of select="name"/>
      <xsl:if test="value != ''">=<xsl:value-of select="value"/></xsl:if>
    </a>
    <xsl:if test="position()!=last()"><xsl:text>, </xsl:text></xsl:if>
  </xsl:for-each>
</xsl:template>

<!-- Resource Permissions -->
<xsl:template name="resource-permissions-window">
  <xsl:param name="resource_type"/>
  <xsl:param name="resource_id" select="@id"/>
  <xsl:param name="next" select="concat('get_',$resource_type)"/>
  <xsl:param name="report_section" select="''"/>
  <!-- i18n with concat : see dynamic_strings.xsl - type-permissions -->
  <xsl:param name="permissions" select="../../permissions/get_permissions_response"/>
  <xsl:param name="related" select="''"/>
  <xsl:variable name="token" select="/envelope/token"/>
  <xsl:if test="gsa:may-op ('get_permissions')">
    <xsl:variable name="related_params">
      <xsl:for-each select="exslt:node-set ($related)/*">
        <xsl:text>related:</xsl:text>
        <xsl:value-of select="@id"/>
        <xsl:text>=</xsl:text>
        <xsl:value-of select="name(.)"/>
        <xsl:if test="position() != last()">
          <xsl:text>&amp;</xsl:text>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <div class="section-header">
      <a href="#" class="toggle-action-icon icon icon-sm icon-action"
        data-target="#permission-box" data-name="Permissions"
        data-variable="permission-box--collapsed">
          <img src="/img/fold.svg"/>
      </a>
      <a href="/help/resource_permissions.html?token={/envelope/token}"
         class="icon icon-sm icon-action"
         title="Help: Resource Permissions">
        <img src="/img/help.svg"/>
      </a>
      <xsl:choose>
        <xsl:when test="gsa:may-op ('create_permission')">
          <a href="/omp?cmd=new_permissions&amp;next={$next}&amp;next_id={$resource_id}&amp;next_type={$resource_type}&amp;resource_id={$resource_id}&amp;restrict_type={$resource_type}&amp;{$related_params}token={/envelope/token}"
             class="new-action-icon icon icon-sm icon-action"
             data-reload="window"
             data-type="permissions"
             data-extra="resource_id={$resource_id}&amp;restrict_type={$resource_type}&amp;{$related_params}"
             title="{gsa:i18n ('Create Multiple Permissions')}">
            <img src="/img/new.svg"/>
          </a>
        </xsl:when>
        <xsl:otherwise/>
      </xsl:choose>
      <h2>
        <a href="/ng/permissions?filter=name:^.*({$resource_type})s?$ and resource_uuid={$resource_id}"
           title="{gsa:i18n ('Permissions')}">
          <img class="icon icon-sm" src="/img/permission.svg" alt="Permissions"/>
        </a>
        <xsl:value-of select="gsa:i18n ('Permissions')"/>
        <xsl:choose>
          <xsl:when test="$permissions/permission_count/filtered != 0">
            (<xsl:value-of select="$permissions/permission_count/filtered"/>)
          </xsl:when>
          <xsl:otherwise>
            (<xsl:value-of select="gsa:i18n ('none', 'Permissions')"/>)
          </xsl:otherwise>
        </xsl:choose>
      </h2>
    </div>

    <div class="section-box" id="permission-box">
      <table class="gbntable">
        <tr class="gbntablehead2">
          <td><xsl:value-of select="gsa:i18n ('Name')"/></td>
          <td><xsl:value-of select="gsa:i18n ('Description')"/></td>
          <td><xsl:value-of select="gsa:i18n ('Resource Type')"/></td>
          <td><xsl:value-of select="gsa:i18n ('Resource')"/></td>
          <td><xsl:value-of select="gsa:i18n ('Subject Type', 'Permission')"/></td>
          <td><xsl:value-of select="gsa:i18n ('Subject', 'Permission')"/></td>
          <td style="width: {gsa:actions-width (4)}px"><xsl:value-of select="gsa:i18n ('Actions')"/></td>
        </tr>
        <xsl:apply-templates select="$permissions/permission">
          <xsl:with-param name="next" select="$next"/>
          <xsl:with-param name="next_type" select="$resource_type"/>
          <xsl:with-param name="next_id" select="$resource_id"/>
        </xsl:apply-templates>
      </table>
    </div>
  </xsl:if>
</xsl:template>

<!-- BEGIN REPORTS MANAGEMENT -->

<xsl:template match="sort">
</xsl:template>

<xsl:template match="apply_overrides">
</xsl:template>

<xsl:template match="all">
</xsl:template>

<xsl:template name="html-import-report-form">
  <div class="edit-dialog">
    <div class="title">
      <xsl:value-of select="gsa:i18n ('Import Report')"/>
    </div>
    <div class="content">
      <form action="/omp" method="post" enctype="multipart/form-data">
        <input type="hidden" name="token" value="{/envelope/token}"/>
        <input type="hidden" name="cmd" value="import_report"/>
        <input type="hidden" name="caller" value="{/envelope/current_page}"/>
        <input type="hidden" name="next" value="get_report"/>
        <xsl:if test="string-length (/envelope/params/filt_id) = 0">
          <input type="hidden" name="overrides" value="{/envelope/params/overrides}"/>
        </xsl:if>
        <input type="hidden" name="filter" value="{gsa:envelope-filter ()}"/>
        <input type="hidden" name="filt_id" value="{/envelope/params/filt_id}"/>
        <table class="table-form">
          <tr>
            <td><xsl:value-of select="gsa:i18n ('Report')"/></td>
            <td><input type="file" name="xml_file" size="30"/></td>
          </tr>
          <tr>
            <td><xsl:value-of select="gsa:i18n ('Container Task')"/></td>
            <td>
              <xsl:variable name="task_id" select="/envelope/params/task_id"/>
              <select name="task_id">
                <xsl:for-each select="get_tasks_response/task[target/@id='']">
                  <xsl:choose>
                    <xsl:when test="@id = $task_id">
                      <option value="{@id}" selected="1"><xsl:value-of select="name"/></option>
                    </xsl:when>
                    <xsl:otherwise>
                      <option value="{@id}"><xsl:value-of select="name"/></option>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:for-each>
              </select>
              <a href="#" title="{ gsa:i18n('Create a new container task') }"
                 class="icon icon-sm new-action-icon" data-type="container_task" data-done="select[name=task_id]">
                <img src="/img/new.svg" class="valign-middle"/>
              </a>
            </td>
          </tr>
          <xsl:if test="gsa:may-op ('create_asset')">
            <tr>
              <td><xsl:value-of select="gsa:i18n ('Add to Assets')"/></td>
              <td>
                <div>
                  <xsl:value-of select="gsa-i18n:strformat (gsa:i18n ('Add to Assets with QoD>=%1%% and Overrides enabled'), 70)"/>
                </div>
                <label>
                  <input type="radio" name="in_assets" value="1" checked="1"/>
                  <xsl:value-of select="gsa:i18n ('yes')"/>
                </label>
                <label>
                  <input type="radio" name="in_assets" value="0"/>
                  <xsl:value-of select="gsa:i18n ('no')"/>
                </label>
              </td>
            </tr>
          </xsl:if>
        </table>
      </form>
    </div>
  </div>
</xsl:template>

<xsl:template match="upload_report">
  <xsl:apply-templates select="gsad_msg"/>
  <xsl:apply-templates select="create_report_response" mode="upload"/>
  <xsl:apply-templates select="commands_response/delete_report_response"/>
  <xsl:call-template name="html-import-report-form"/>
</xsl:template>

<xsl:template match="get_reports_response" mode="alert">
  <xsl:call-template name="command_result_dialog">
    <xsl:with-param name="operation">Run Alert</xsl:with-param>
    <xsl:with-param name="status">
      <xsl:value-of select="@status"/>
    </xsl:with-param>
    <xsl:with-param name="msg">
      <xsl:value-of select="@status_text"/>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template match="report" mode="sorting-link">
  <xsl:param name="field"/>
  <xsl:param name="order"/>
  <xsl:param name="levels"/>
  <xsl:param name="name"><xsl:value-of select="$field"/></xsl:param>

  <xsl:choose>
    <xsl:when test="sort/field/text() = $field and sort/field/order = $order">
      <xsl:value-of select="concat($name, ' ', $order)"/>
    </xsl:when>
    <xsl:otherwise>
        <a href="/omp?cmd=get_report&amp;report_id={@id}&amp;delta_report_id={delta/report/@id}&amp;delta_states={filters/delta/text()}&amp;sort_field={$field}&amp;sort_order={$order}&amp;max_results={results/@max}&amp;levels={$levels}&amp;notes={filters/notes}&amp;details={/envelope/params/details}&amp;overrides={filters/overrides}&amp;result_hosts_only={filters/result_hosts_only}&amp;autofp={filters/autofp}&amp;token={/envelope/token}">
        <xsl:value-of select="concat($name, ' ', $order)"/>
      </a>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="result-details-icon-img">
  <xsl:param name="details"/>
  <xsl:choose>
    <xsl:when test="$details = 1">
      <img src="/img/fold.svg"
        class="icon icon-sm"
        alt="{gsa:i18n ('Collapse details of all vulnerabilities')}"
        title="{gsa:i18n ('Collapse details of all vulnerabilities')}"/>
    </xsl:when>
    <xsl:otherwise>
      <img src="/img/unfold.svg"
        class="icon icon-sm"
        alt="{gsa:i18n ('Expand to full details of all vulnerabilities')}"
        title="{gsa:i18n ('Expand to full details of all vulnerabilities')}"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="report" mode="result-details-icon">
  <xsl:variable name="details">
    <xsl:choose>
      <xsl:when test="/envelope/params/details &gt; 0">1</xsl:when>
      <xsl:otherwise>0</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="filter_term">
    <xsl:choose>
      <xsl:when test="/envelope/params/cmd='get_report_section' and /envelope/params/report_section != 'results'">
        <xsl:value-of select="/envelope/params/filter"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="filters/term"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="host" select="/envelope/params/host"/>
  <xsl:variable name="pos" select="/envelope/params/pos"/>
  <xsl:variable name="delta" select="delta/report/@id"/>

  <xsl:variable name="expand" select="($details - 1)*($details - 1)"/>
  <xsl:variable name="apply_filter" select="/envelope/params/apply_filter"/>
  <xsl:variable name="link">
    <xsl:choose>
      <xsl:when test="@type='delta'">
        <xsl:value-of select="concat('/omp?cmd=get_report&amp;report_id=', @id, '&amp;delta_report_id=', $delta, '&amp;details=', $expand, '&amp;apply_filter=', $apply_filter, '&amp;filter=', $filter_term, '&amp;filt_id=', /envelope/params/filt_id, '&amp;token=', /envelope/token)"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="concat('/omp?cmd=get_report&amp;report_id=', @id, '&amp;details=', $expand, '&amp;apply_filter=', $apply_filter, '&amp;filter=', $filter_term, '&amp;filt_id=', /envelope/params/filt_id, '&amp;token=', /envelope/token)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="title">
    <xsl:choose>
      <xsl:when test="$expand=1">
        <xsl:value-of select="'Expand to full details of all vulnerabilities'"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="'Collapse details of all vulnerabilities'"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <a href="{$link}" title="{$title}">
     <xsl:call-template name="result-details-icon-img">
       <xsl:with-param name="details" select="$details"/>
     </xsl:call-template>
  </a>
</xsl:template>

<xsl:template match="report" mode="filterbox">
  <input type="hidden" name="build_filter" value="0"/>
  <div id="filterbox" style="display: none;">
    <div style="background-color: #EEEEEE;">
      <xsl:choose>
        <xsl:when test="/envelope/params/report_section != ''">
          <input type="hidden" name="report_section" value="{/envelope/params/report_section}"/>
          <input type="hidden" name="cmd" value="get_report_section"/>
        </xsl:when>
        <xsl:otherwise>
          <input type="hidden" name="cmd" value="get_report"/>
        </xsl:otherwise>
      </xsl:choose>
      <input type="hidden" name="report_id" value="{report/@id}"/>
      <input type="hidden" name="details" value="{/envelope/params/details}"/>
      <input type="hidden" name="token" value="{/envelope/token}"/>
      <xsl:if test="../../delta">
        <input type="hidden" name="delta_report_id" value="{report/delta/report/@id}"/>
        <div class="pull-right">
          <div class="form-group"><xsl:value-of select="gsa:i18n ('Show delta results')"/>:</div>
          <div style="margin-left: 8px;">
            <label>
              <xsl:choose>
                <xsl:when test="report/filters/delta/same = 0">
                  <input type="checkbox" name="delta_state_same" value="1"/>
                </xsl:when>
                <xsl:otherwise>
                  <input type="checkbox" name="delta_state_same"
                          value="1" checked="1"/>
                </xsl:otherwise>
              </xsl:choose>
              = <xsl:value-of select="gsa:i18n ('same', 'Delta Result')"/>
            </label>
          </div>
          <div style="margin-left: 8px;">
            <label>
              <xsl:choose>
                <xsl:when test="report/filters/delta/new = 0">
                  <input type="checkbox" name="delta_state_new" value="1"/>
                </xsl:when>
                <xsl:otherwise>
                  <input type="checkbox" name="delta_state_new"
                          value="1" checked="1"/>
                </xsl:otherwise>
              </xsl:choose>
              + <xsl:value-of select="gsa:i18n ('new', 'Delta Result')"/>
            </label>
          </div>
          <div style="margin-left: 8px;">
            <label>
              <xsl:choose>
                <xsl:when test="report/filters/delta/gone = 0">
                  <input type="checkbox" name="delta_state_gone" value="1"/>
                </xsl:when>
                <xsl:otherwise>
                  <input type="checkbox" name="delta_state_gone"
                          value="1" checked="1"/>
                </xsl:otherwise>
              </xsl:choose>
              &#8722; <xsl:value-of select="gsa:i18n ('gone', 'Delta Result')"/>
            </label>
          </div>
          <div style="margin-left: 8px;">
            <label>
              <xsl:choose>
                <xsl:when test="report/filters/delta/changed = 0">
                  <input type="checkbox" name="delta_state_changed" value="1"/>
                </xsl:when>
                <xsl:otherwise>
                  <input type="checkbox" name="delta_state_changed"
                          value="1" checked="1"/>
                </xsl:otherwise>
              </xsl:choose>
              ~ <xsl:value-of select="gsa:i18n ('changed', 'Delta Result')"/>
            </label>
          </div>
        </div>
      </xsl:if>

      <xsl:if test="not (/envelope/params/report_section) or /envelope/params/report_section = 'results'">
        <div class="form-group">
          <xsl:value-of select="gsa:i18n ('Results per page')"/>:
          <input type="text" name="max_results" size="5"
                value="{report/results/@max}"
                maxlength="400"/>
        </div>
      </xsl:if>

      <div class="form-group">
        <label>
          <xsl:choose>
            <xsl:when test="report/filters/keywords/keyword[column = 'apply_overrides']/value = 0">
              <input type="checkbox" name="apply_overrides" value="1"/>
            </xsl:when>
            <xsl:otherwise>
              <input type="checkbox" name="apply_overrides" value="1" checked="1"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:value-of select="gsa:i18n ('Apply Overrides')"/>
        </label>
      </div>

          <div class="form-group">
            <xsl:value-of select="gsa:i18n ('Auto-FP')"/>:
            <div style="margin-left: 30px">
              <label>
                <xsl:choose>
                  <xsl:when test="report/filters/keywords/keyword[column = 'autofp']/value = 0">
                    <input type="checkbox" name="autofp" value="1"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <input type="checkbox" name="autofp" value="1" checked="1"/>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:value-of select="gsa:i18n ('Trust vendor security updates')"/>
              </label>
              <div style="margin-left: 30px">
                <label>
                  <xsl:choose>
                    <xsl:when test="report/filters/keywords/keyword[column = 'autofp']/value = 2">
                      <input type="radio" name="autofp_value" value="1"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <input type="radio" name="autofp_value" value="1" checked="1"/>
                    </xsl:otherwise>
                  </xsl:choose>
                  <xsl:value-of select="gsa:i18n ('Full CVE match')"/>
                </label>
                <label>
                  <xsl:choose>
                    <xsl:when test="report/filters/keywords/keyword[column = 'autofp']/value = 2">
                      <input type="radio" name="autofp_value" value="2" checked="1"/>
                    </xsl:when>
                    <xsl:otherwise>
                      <input type="radio" name="autofp_value" value="2"/>
                    </xsl:otherwise>
                  </xsl:choose>
                  <xsl:value-of select="gsa:i18n ('Partial CVE match')"/>
                </label>
              </div>
            </div>
          </div>

          <div class="form-group">
            <label>
              <xsl:choose>
                <xsl:when test="report/filters/keywords/keyword[column = 'notes']/value = 0">
                  <input type="checkbox" name="notes" value="1"/>
                </xsl:when>
                <xsl:otherwise>
                  <input type="checkbox" name="notes" value="1" checked="1"/>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:value-of select="gsa:i18n ('Show Notes')"/>
            </label>
          </div>

      <div class="form-group">
        <label>
          <xsl:choose>
            <xsl:when test="report/filters/keywords/keyword[column = 'overrides']/value = 0">
              <input type="checkbox" name="overrides" value="1"/>
            </xsl:when>
            <xsl:otherwise>
              <input type="checkbox" name="overrides" value="1" checked="1"/>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:value-of select="gsa:i18n ('Show Overrides')"/>
        </label>
      </div>

      <div class="form-group">
        <xsl:choose>
          <xsl:when test="report/filters/keywords/keyword[column = 'result_hosts_only']/value = 0">
            <label>
              <input type="checkbox" name="result_hosts_only" value="1"/>
              <xsl:value-of select="gsa:i18n ('Only show hosts that have results')"/>
            </label>
          </xsl:when>
          <xsl:otherwise>
            <label>
              <input type="checkbox" name="result_hosts_only" value="1" checked="1"/>
              <xsl:value-of select="gsa:i18n ('Only show hosts that have results')"/>
            </label>
          </xsl:otherwise>
        </xsl:choose>
      </div>
      <div class="form-group">
        <label>
          QoD &gt;=
        </label>
        <select name="min_qod">
          <xsl:call-template name="opt">
            <xsl:with-param name="value" select="'100'"/>
            <xsl:with-param name="select-value" select="report/filters/keywords/keyword[column = 'min_qod']/value"/>
          </xsl:call-template>
          <xsl:call-template name="opt">
            <xsl:with-param name="value" select="'90'"/>
            <xsl:with-param name="select-value" select="report/filters/keywords/keyword[column = 'min_qod']/value"/>
          </xsl:call-template>
          <xsl:call-template name="opt">
            <xsl:with-param name="value" select="'80'"/>
            <xsl:with-param name="select-value" select="report/filters/keywords/keyword[column = 'min_qod']/value"/>
          </xsl:call-template>
          <xsl:choose>
            <xsl:when test="not (report/filters/keywords/keyword[column = 'min_qod']/value != '')">
              <xsl:call-template name="opt">
                <xsl:with-param name="value" select="'70'"/>
                <xsl:with-param name="select-value" select="'70'"/>
              </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
              <xsl:call-template name="opt">
                <xsl:with-param name="value" select="'70'"/>
                <xsl:with-param name="select-value" select="report/filters/keywords/keyword[column = 'min_qod']/value"/>
              </xsl:call-template>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:call-template name="opt">
            <xsl:with-param name="value" select="'60'"/>
            <xsl:with-param name="select-value" select="report/filters/keywords/keyword[column = 'min_qod']/value"/>
          </xsl:call-template>
          <xsl:call-template name="opt">
            <xsl:with-param name="value" select="'50'"/>
            <xsl:with-param name="select-value" select="report/filters/keywords/keyword[column = 'min_qod']/value"/>
          </xsl:call-template>
          <xsl:call-template name="opt">
            <xsl:with-param name="value" select="'40'"/>
            <xsl:with-param name="select-value" select="report/filters/keywords/keyword[column = 'min_qod']/value"/>
          </xsl:call-template>
          <xsl:call-template name="opt">
            <xsl:with-param name="value" select="'30'"/>
            <xsl:with-param name="select-value" select="report/filters/keywords/keyword[column = 'min_qod']/value"/>
          </xsl:call-template>
          <xsl:call-template name="opt">
            <xsl:with-param name="value" select="'20'"/>
            <xsl:with-param name="select-value" select="report/filters/keywords/keyword[column = 'min_qod']/value"/>
          </xsl:call-template>
          <xsl:call-template name="opt">
            <xsl:with-param name="value" select="'10'"/>
            <xsl:with-param name="select-value" select="report/filters/keywords/keyword[column = 'min_qod']/value"/>
          </xsl:call-template>
          <xsl:call-template name="opt">
            <xsl:with-param name="value" select="'0'"/>
            <xsl:with-param name="select-value" select="report/filters/keywords/keyword[column = 'min_qod']/value"/>
          </xsl:call-template>
        </select>
        %
      </div>
      <div class="form-group">
        <xsl:value-of select="gsa:i18n ('Timezone')"/>:
        <xsl:call-template name="timezone-select">
          <xsl:with-param name="timezone" select="report/timezone"/>
          <xsl:with-param name="input-name" select="'timezone'"/>
        </xsl:call-template>
      </div>
      <div class="pull-right">
        <input type="submit" value="{gsa:i18n ('Apply')}" title="{gsa:i18n ('Apply')}"/>
      </div>
      <div class="form-group">
        <xsl:value-of select="gsa:i18n ('Severity')"/>:
        <table style="display: inline">
          <tr>
            <td class="threat_info_table_h">
              <label>
                <xsl:choose>
                  <xsl:when test="report/filters/filter[text()='High']">
                    <input type="checkbox" name="level_high" value="1"
                            checked="1"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <input type="checkbox" name="level_high" value="1"/>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:call-template name="severity-label">
                  <xsl:with-param name="level" select="'High'"/>
                </xsl:call-template>
              </label>
            </td>
            <td class="threat_info_table_h">
              <label>
                <xsl:choose>
                  <xsl:when test="report/filters/filter[text()='Medium']">
                    <input type="checkbox" name="level_medium" value="1"
                            checked="1"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <input type="checkbox" name="level_medium" value="1"/>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:call-template name="severity-label">
                  <xsl:with-param name="level" select="'Medium'"/>
                </xsl:call-template>
              </label>
            </td>
            <td class="threat_info_table_h">
              <label>
                <xsl:choose>
                  <xsl:when test="report/filters/filter[text()='Low']">
                    <input type="checkbox" name="level_low" value="1"
                            checked="1"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <input type="checkbox" name="level_low" value="1"/>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:call-template name="severity-label">
                  <xsl:with-param name="level" select="'Low'"/>
                </xsl:call-template>
              </label>
            </td>
            <td class="threat_info_table_h">
              <label>
                <xsl:choose>
                  <xsl:when test="report/filters/filter[text()='Log']">
                    <input type="checkbox" name="level_log" value="1"
                            checked="1"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <input type="checkbox" name="level_log" value="1"/>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:call-template name="severity-label">
                  <xsl:with-param name="level" select="'Log'"/>
                </xsl:call-template>
              </label>
            </td>
            <td class="threat_info_table_h">
              <label>
                <xsl:choose>
                  <xsl:when test="report/filters/filter[text()='False Positive']">
                    <input type="checkbox"
                            name="level_false_positive"
                            value="1"
                            checked="1"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <input type="checkbox"
                            name="level_false_positive"
                            value="1"/>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:call-template name="severity-label">
                  <xsl:with-param name="level" select="'False Positive'"/>
                </xsl:call-template>
              </label>
            </td>
          </tr>
        </table>
      </div>
    </div>
  </div>
</xsl:template>

<xsl:template match="report" mode="section-filter-restricted">
  <xsl:param name="report_section" select="'results'"/>
  <xsl:param name="extra_params" select="''"/>

  <xsl:variable name="filter_term" select="/envelope/params/filter"/>
  <xsl:variable name="apply-overrides"
                select="filters/apply_overrides"/>

  <div id="list-window-filter" class="col-8">
    <form name="filterform" method="get" action="" enctype="multipart/form-data" class="pull-right">
      <input type="hidden" name="token" value="{/envelope/token}"/>
      <input type="hidden" name="cmd" value="get_report_section"/>
      <input type="hidden" name="report_id" value="{@id}"/>
      <input type="hidden" name="report_section" value="{$report_section}"/>
      <input type="hidden" name="overrides" value="{$apply-overrides}"/>
      <input type="hidden" name="details" value="{/envelope/params/details}"/>
      <xsl:if test="@type='delta'">
        <input type="hidden" name="delta_report_id" value="{delta/report/@id}"/>
      </xsl:if>
      <select name="apply_filter" style="min-width:250px">
        <xsl:choose>
          <xsl:when test="/envelope/params/apply_filter = 'no_pagination' or not(/envelope/params/apply_filter != '')">
            <option value="no_pagination" selected="1">&#8730;<xsl:value-of select="gsa:i18n ('Use filtered results (all pages)')"/></option>
          </xsl:when>
          <xsl:otherwise>
            <option value="no_pagination"><xsl:value-of select="gsa:i18n ('Use filtered results (all pages)')"/></option>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="/envelope/params/apply_filter = 'no'">
            <option value="no" selected="1">&#8730;<xsl:value-of select="gsa:i18n ('Use all unfiltered results')"/></option>
          </xsl:when>
          <xsl:otherwise>
            <option value="no"><xsl:value-of select="gsa:i18n ('Use all unfiltered results')"/></option>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:choose>
          <xsl:when test="/envelope/params/apply_filter = 'full' or /envelope/params/apply_filter = ''">
            <option value="full" selected="1">&#8730;<xsl:value-of select="gsa:i18n ('Use filtered results (current page)')"/></option>
          </xsl:when>
          <xsl:otherwise>
            <option value="full"><xsl:value-of select="gsa:i18n ('Use filtered results (current page)')"/></option>
          </xsl:otherwise>
        </xsl:choose>
      </select>
      <xsl:text> </xsl:text>
      <xsl:choose>
        <xsl:when test="/envelope/params/apply_filter = 'no'">
          <input type="text" name="filter" size="53"
                  value="{$filter_term}" style="color:silver"
                  maxlength="1000"/>
        </xsl:when>
        <xsl:otherwise>
          <input type="text" name="filter" size="53"
                  value="{$filter_term}"
                  maxlength="1000"/>
        </xsl:otherwise>
      </xsl:choose>
      <input type="image"
        name="Update Filter"
        title="{gsa:i18n ('Update Filter')}"
        src="/img/refresh.svg"
        class="icon icon-sm"
        alt="{gsa:i18n ('Update', 'Action Verb')}" style="vertical-align:middle;margin-left:3px;margin-right:3px;"/>
      <a href="/help/powerfilter.html?token={/envelope/token}" title="{gsa:i18n ('Help')}: {gsa:i18n ('Powerfilter')}"
        class="icon icon-sm">
        <img src="/img/help.svg"/>
      </a>
    </form>
  </div>
</xsl:template>

<xsl:template match="report" mode="section-filter-full">
  <xsl:param name="report_section" select="'results'"/>
  <xsl:param name="extra_params" select="''"/>

  <div id="list-window-filter" class="col-8">
    <xsl:call-template name="filter-window-part">
      <xsl:with-param name="type" select="'report_result'"/>
      <xsl:with-param name="subtype" select="''"/>
      <xsl:with-param name="list" select="report/results"/>
      <xsl:with-param name="full-count" select="result_count/full/text ()"/>
      <xsl:with-param name="columns" xmlns="">
        <column>
          <name><xsl:value-of select="gsa:i18n('Vulnerability')"/></name>
          <field>vulnerability</field>
        </column>
        <column>
          <name><xsl:value-of select="gsa:i18n('Solution type')"/></name>
          <field>solution_type</field>
        </column>
        <column>
          <name><xsl:value-of select="gsa:i18n('Severity')"/></name>
          <field>severity</field>
        </column>
        <column>
          <name><xsl:value-of select="gsa:i18n('QoD')"/></name>
          <field>qod</field>
        </column>
        <column>
          <name><xsl:value-of select="gsa:i18n('Host')"/></name>
          <field>host</field>
        </column>
        <column>
          <name><xsl:value-of select="gsa:i18n('Location', 'Host')"/></name>
          <field>location</field>
        </column>
      </xsl:with-param>
      <xsl:with-param name="filter_options" xmlns="">
        <xsl:if test="delta">
          <option>delta_states</option>
        </xsl:if>
        <option>apply_overrides</option>
        <option>autofp</option>
        <option>notes</option>
        <option>overrides</option>
        <option>result_hosts_only</option>
        <option>min_qod</option>
        <option>timezone</option>
        <option>levels</option>
        <option>first</option>
        <option>rows</option>
      </xsl:with-param>
      <xsl:with-param name="extra_params" xmlns="">
        <xsl:copy-of select="$extra_params"/>
        <param>
          <name>report_id</name>
          <value><xsl:value-of select="@id"/></value>
        </param>
        <param>
          <name>report_section</name>
          <value><xsl:value-of select="$report_section"/></value>
        </param>
        <xsl:if test="../@type != '' and ../@type != 'scan'">
          <param>
            <name>type</name>
            <value><xsl:value-of select="../@type"/></value>
          </param>
        </xsl:if>
        <xsl:if test="delta/report/@id">
          <param>
            <name>delta_report_id</name>
            <value><xsl:value-of select="delta/report/@id"/></value>
          </param>
        </xsl:if>
      </xsl:with-param>
      <xsl:with-param name="filters" select="../../../filters"/>
      <xsl:with-param name="report_section" select="$report_section"/>
    </xsl:call-template>
  </div>
</xsl:template>

<xsl:template match="report" mode="section-pager">
  <xsl:param name="section"/>
  <xsl:param name="count"/>
  <xsl:param name="filtered-count"/>
  <xsl:param name="full-count"/>

  <xsl:call-template name="filter-window-pager">
    <xsl:with-param name="type" select="'report_result'"/>
    <xsl:with-param name="list" select="results"/>
    <xsl:with-param name="count" select="$count"/>
    <xsl:with-param name="filtered_count" select="$filtered-count"/>
    <xsl:with-param name="full_count" select="$full-count"/>
    <xsl:with-param name="extra_params">
      <xsl:text>&amp;report_id=</xsl:text><xsl:value-of select="@id"/>
      <xsl:text>&amp;report_section=</xsl:text><xsl:value-of select="$section"/>
      <xsl:text>&amp;apply_overrides=</xsl:text><xsl:value-of select="/envelope/params/apply_overrides"/>
      <xsl:text>&amp;details=</xsl:text><xsl:value-of select="/envelope/params/details"/>
      <xsl:if test="@type='delta'">
        <xsl:text>&amp;delta_report_id=</xsl:text><xsl:value-of select="delta/report/@id"/>
      </xsl:if>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="report-section-header">
  <xsl:param name="section" select="'results'"/>
  <xsl:param name="filtered-count" select="''"/>
  <xsl:param name="full-count" select="''"/>

  <div id="list-window-header">
    <div id="list-window-title">
      <div class="section-header">
        <div class="section-header-info">
          <table>
            <tr>
              <td><xsl:value-of select="gsa:i18n ('ID')"/>:</td>
              <td>
                <xsl:value-of select="@id"/>
              </td>
            </tr>
            <tr>
              <td><xsl:value-of select="gsa:i18n ('Modified', 'Date')"/>:</td>
              <td><xsl:value-of select="gsa:long-time (modification_time)"/></td>
            </tr>
            <tr>
              <td><xsl:value-of select="gsa:i18n ('Created', 'Date')"/>:</td>
              <td><xsl:value-of select="gsa:long-time (creation_time)"/></td>
            </tr>
            <tr>
              <td><xsl:value-of select="gsa:i18n ('Owner')"/>:</td>
              <td><xsl:value-of select="owner/name"/></td>
            </tr>
          </table>
        </div>

        <xsl:choose>
          <xsl:when test="0">
          </xsl:when>
          <xsl:otherwise>
            <img class="icon icon-lg" src="/img/vul_report.svg"/>
          </xsl:otherwise>
        </xsl:choose>

        <h1>
          <xsl:apply-templates select="report" mode="section-list">
            <xsl:with-param name="current" select="$section"/>
          </xsl:apply-templates>
          <xsl:if test="$filtered-count != ''">
            <xsl:text> (</xsl:text>
            <xsl:choose>
              <xsl:when test="$full-count != ''">
                <xsl:value-of select="gsa-i18n:strformat (gsa:i18n ('%1 of %2'), $filtered-count, $full-count)"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="$filtered-count"/>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:text>)</xsl:text>
          </xsl:if>
        </h1>
      </div>
    </div>
  </div>
</xsl:template>

<xsl:template match="report" mode="results">
  <xsl:variable name="levels"
                select="report/filters/keywords/keyword[column = 'levels']/value"/>
  <xsl:variable name="apply-overrides"
                select="report/filters/keywords/keyword[column = 'apply_overrides']/value"/>
  <xsl:variable name="type">
    <xsl:choose>
      <xsl:when test="@type"><xsl:value-of select="@type"/></xsl:when>
      <xsl:otherwise>normal</xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:apply-templates select="." mode="report-section-toolbar">
    <xsl:with-param name="section" select="'results'"/>
  </xsl:apply-templates>
  <xsl:call-template name="report-section-header">
    <xsl:with-param name="section" select="'results'"/>
    <xsl:with-param name="filtered-count" select="report/result_count/filtered"/>
    <xsl:with-param name="full-count" select="report/result_count/full"/>
  </xsl:call-template>

  <div id="table-box" class="section-box">
      <xsl:choose>
        <xsl:when test="count(report/results/result) &gt; 0">
          <div id="reports">
            <div class="footnote" style="text-align:right;">
              <xsl:apply-templates select="report" mode="section-pager">
                <xsl:with-param name="report_section" select="'results'"/>
                <xsl:with-param name="count" select="count (report/results/result)"/>
                <xsl:with-param name="filtered-count" select="report/result_count/filtered"/>
                <xsl:with-param name="full-count" select="report/result_count/full"/>
              </xsl:apply-templates>
            </div>
            <table class="gbntable">
              <xsl:apply-templates select="report" mode="details"/>
              <tr>
                <td class="footnote" colspan="1000">
                  <xsl:variable name="delta">
                    <xsl:if test="report/@type='delta'">
                      <xsl:value-of select="concat ('&amp;delta_report_id=', report/delta/report/@id)"/>
                    </xsl:if>
                  </xsl:variable>
                  <div class="pull-right">
                    <xsl:apply-templates select="report" mode="section-pager">
                      <xsl:with-param name="report_section" select="'results'"/>
                      <xsl:with-param name="count" select="count (report/results/result)"/>
                      <xsl:with-param name="filtered-count" select="report/result_count/filtered"/>
                      <xsl:with-param name="full-count" select="report/result_count/full"/>
                    </xsl:apply-templates>
                  </div>
                  (<xsl:value-of select="gsa:i18n('Applied filter:')"/>
                  <a class="footnote"
                     href="/omp?cmd=get_report_section&amp;report_id={report/@id}&amp;report_section=results&amp;overrides={$apply-overrides}&amp;details={/envelope/params/details}&amp;filter={report/filters/term}{$delta}&amp;token={/envelope/token}">
                    <xsl:value-of select="report/filters/term"/>
                  </a>)
                </td>
              </tr>
            </table>
          </div>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="report_url" select="concat ('/omp?token=', /envelope/token, '&amp;cmd=get_report_section&amp;report_id=', report/@id, '&amp;report_section=results')"/>
          <div class="result-info">
            <xsl:choose>
              <xsl:when test="report/result_count/full = 0">
                <p class="alert alert-info"><xsl:value-of select="gsa:i18n ('The report is empty. This can happen for the following reasons:')"/></p>
                <ul>
                  <xsl:choose>
                    <xsl:when test="report/task/progress = 1">
                      <li class="panel panel-info">
                        <div class="panel-heading">
                          <xsl:value-of select="gsa:i18n ('The scan just started and no results have arrived yet.')"/>
                        </div>
                        <p class="panel-body">
                          <a href="{/envelope/current_page}&amp;token={/envelope/token}">
                            <img src="/img/refresh.svg" class="icon icon-lg valign-middle"/>
                            <span>
                              <xsl:value-of select="gsa:i18n ('Click here to reload this page and update the status.')"/>
                            </span>
                          </a>
                        </p>
                      </li>
                    </xsl:when>
                    <xsl:when test="report/task/progress &gt; 1">
                      <li class="panel panel-info">
                        <div class="panel-heading">
                          <xsl:value-of select="gsa:i18n ('The scan is still running and no results have arrived yet.')"/>
                        </div>
                        <p class="panel-body">
                          <a href="{/envelope/current_page}&amp;token={/envelope/token}">
                            <img src="/img/refresh.svg" class="icon icon-lg valign-middle"/>
                            <span>
                              <xsl:value-of select="gsa:i18n ('Click here to reload this page and update the status.')"/>
                            </span>
                          </a>
                        </p>
                      </li>
                    </xsl:when>
                    <xsl:otherwise>
                      <li class="panel panel-info">
                        <div class="panel-heading">
                          <xsl:value-of select="gsa:i18n ('The target hosts could be regarded dead.')"/>
                        </div>
                        <div class="panel-body">
                          <xsl:choose>
                            <xsl:when test="gsa:may-op ('modify_target')">
                              <!-- i18n with concat : see dynamic_strings.xsl - type-edit -->
                              <a href="/omp?cmd=edit_target&amp;target_id={report/task/target/@id}&amp;next=get_report&amp;filter={str:encode-uri (/envelope/params/filter, true ())}&amp;filt_id={/envelope/params/filt_id}&amp;token={/envelope/token}" data-reload="window"
                                class="edit-action-icon" data-type="target" data-id="{report/task/target/@id}"
                                title="{gsa:i18n ('Edit Target')}">
                                <img src="/img/target.svg" class="icon icon-lg"/>
                                <span>
                                  <xsl:value-of select="gsa:i18n ('You could change the Alive Test method of the target. However, if the targets are indeed dead, the scan duration might increase significantly.')"/>
                                  <xsl:text> (</xsl:text>
                                  <xsl:value-of select="gsa:i18n ('Click here to edit the target')"/>
                                  <xsl:text>)</xsl:text>
                                </span>
                              </a>
                            </xsl:when>
                            <xsl:otherwise>
                              <img src="/img/target.svg" class="icon icon-lg"/>
                              <span>
                                <xsl:value-of select="gsa:i18n ('You could change the Alive Test method of the target. However, if the targets are indeed dead, the scan duration might increase significantly.')"/>
                              </span>
                            </xsl:otherwise>
                          </xsl:choose>
                        </div>
                      </li>
                    </xsl:otherwise>
                  </xsl:choose>
                </ul>
              </xsl:when>
              <xsl:when test="report/result_count/full &gt; 0">
                <p class="alert alert-info">
                  <xsl:value-of select="gsa:i18n ('The report is empty.')"/>
                  <xsl:value-of select="' '"/>
                  <b><xsl:value-of select="gsa-i18n:strformat (gsa:i18n ('The filter does not match any of %1 results.'), report/result_count/full)"/></b>
                </p>
                <ul>
                  <xsl:if test="not (contains ($levels, 'g'))">
                    <xsl:variable name="filter" select="gsa:build-filter (report/filters, 'levels', 'levels=hmlg')" />
                    <li class="panel panel-info">
                      <div class="panel-heading">
                        <xsl:choose>
                          <xsl:when test="number(report/severity/full) = 0">
                            <xsl:value-of select="gsa:i18n ('The report only contains log messages, which are currently excluded.')"/>
                          </xsl:when>
                          <xsl:otherwise>
                            <xsl:value-of select="gsa:i18n ('Log messages are currently excluded.')"/>
                          </xsl:otherwise>
                        </xsl:choose>
                      </div>
                      <p class="panel-body">
                        <a href="{$report_url}&amp;filter={$filter}"
                          title="{gsa:i18n ('Add log messages to the filter')}">
                          <img src="/img/filter.svg" class="valign-middle icon icon-lg"/>
                          <span>
                            <xsl:value-of select="gsa:i18n ('Include log messages in your filter setting.')"/>
                          </span>
                        </a>
                      </p>
                    </li>
                  </xsl:if>
                  <xsl:if test="contains (report/filters/term, 'severity>')">
                    <xsl:variable name="filter" select="gsa:build-filter (report/filters, 'severity', '')" />
                    <li class="panel panel-info">
                      <div class="panel-heading">
                        <xsl:value-of select="gsa:i18n ('You are using keywords setting a minimum limit on severity.')"/>
                      </div>
                      <p class="panel-body">
                        <a href="{$report_url}&amp;filter={$filter}"
                          title="{gsa:i18n ('Remove severity limit')}">
                          <img src="/img/filter.svg" class="valign-middle icon icon-lg"/>
                          <span>
                            <xsl:value-of select="gsa:i18n ('Remove the severity limit from your filter settings.')"/>
                          </span>
                        </a>
                      </p>
                    </li>
                  </xsl:if>
                  <xsl:if test="report/filters/keywords/keyword[column='min_qod']/value > 30">
                    <xsl:variable name="filter" select="gsa:build-filter (report/filters, 'min_qod', 'min_qod=30')" />
                    <li class="panel panel-info">
                      <div class="panel-heading">
                        <xsl:value-of select="gsa:i18n ('There may be results below the current minimum Quality of Detection level.')"/>
                      </div>
                      <p class="panel-body">
                        <a href="{$report_url}&amp;filter={$filter}"
                          title="{gsa:i18n ('Descrease minimum QoD')}">
                          <img src="/img/filter.svg" class="valign-middle icon icon-lg"/>
                          <span>
                            <xsl:value-of select="gsa:i18n ('Decrease the minimum QoD in the Filter to 30 percent to see those results.')"/>
                          </span>
                        </a>
                      </p>
                    </li>
                  </xsl:if>
                  <xsl:if test="report/filters/keywords/keyword[column='qod' and not (relation='&lt;')]">
                    <xsl:variable name="filter" select="gsa:build-filter (report/filters, 'qod', '')" />
                    <li class="panel panel-info">
                      <div class="panel-heading">
                        <xsl:value-of select="gsa:i18n ('You are using keywords setting a lower limit on QoD.')"/>
                      </div>
                      <p class="panel-body">
                        <a href="{$report_url}&amp;filter={$filter}"
                          title="{gsa:i18n ('Remove QoD limit')}">
                          <img src="/img/filter.svg" class="valign-middle icon icon-lg"/>
                          <span>
                            <xsl:value-of select="gsa:i18n ('Remove Quality of Detection limit.')"/>
                          </span>
                        </a>
                      </p>
                    </li>
                  </xsl:if>
                  <li class="panel panel-info">
                    <div class="panel-heading">
                      <xsl:value-of select="gsa:i18n ('Your filter settings may be too refined.')"/>
                    </div>
                    <p class="panel-body">
                      <a href="#" class="edit-filter-action-icon"
                        data-id="filterbox" title="{gsa:i18n ('Edit filter')}">
                        <img src="/img/edit.svg" class="valign-middle icon icon-lg"/>
                        <span>
                          <xsl:value-of select="gsa:i18n ('Adjust and update your filter settings.')"/>
                        </span>
                      </a>
                    </p>
                  </li>
                  <li class="panel panel-info">
                    <div class="panel-heading">
                      <xsl:value-of select="gsa:i18n ('Your last filter change may be too restrictive.')"/>
                    </div>
                    <p class="panel-body">
                      <a href="/omp?token={/envelope/token}&amp;cmd=get_report_section&amp;report_id={report/@id}&amp;report_section=results&amp;filt_id=--"
                        title="{gsa:i18n ('Reset filter')}">
                        <img src="/img/delete.svg" class="valign-middle icon icon-lg"/>
                        <span>
                          <xsl:value-of select="gsa:i18n ('Reset the filter settings to the defaults.')"/>
                        </span>
                      </a>
                    </p>
                  </li>
                </ul>
              </xsl:when>
            </xsl:choose>
          </div>
        </xsl:otherwise>
      </xsl:choose>
  </div>
</xsl:template>


<!-- BEGIN TASKS MANAGEMENT -->

<xsl:template name="task-icons">
  <xsl:param name="next" select="'get_tasks'"/>
  <xsl:param name="enable-resume-when-scheduled" select="false ()"/>
  <xsl:param name="show-start-when-scheduled" select="false ()"/>
  <xsl:param name="show-stop-when-scheduled" select="false ()"/>
  <xsl:choose>
    <xsl:when test="target/@id = ''">
      <a href="/omp?cmd=upload_report&amp;next=get_report&amp;task_id={@id}&amp;filter={str:encode-uri (filters/term, true ())}&amp;filt_id={/envelope/params/filt_id}&amp;token={/envelope/token}"
         class="upload-action-icon icon icon-sm" data-type="report"
         data-task_id="{@id}" data-reload="window"
         title="{gsa:i18n ('Import Report')}">
        <img src="/img/upload.svg"/>
      </a>
    </xsl:when>
    <xsl:when test="gsa:may ('start_task') = 0">
      <img class="icon icon-sm" src="/img/start_inactive.svg"
        alt="{gsa:i18n ('Start', 'Action Verb')}" title="{gsa:i18n ('Permission to start task denied')}"/>
    </xsl:when>
    <xsl:when test="string-length(schedule/@id) &gt; 0">
      <xsl:choose>
        <xsl:when test="boolean (schedule/permissions) and count (schedule/permissions/permission) = 0">
          <img class="icon icon-sm" src="/img/scheduled_inactive.svg"
               alt="{gsa:i18n ('Schedule Unavailable')}"
               title="{gsa:i18n ('Schedule Unavailable')} ({gsa:i18n ('Name')}: {schedule/name}, ID: {schedule/@id})"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="next_due_string">
            <xsl:choose>
              <xsl:when test="schedule/next_time = 'over'">
    <xsl:text>
    (</xsl:text>
                <xsl:value-of select="gsa:i18n ('Next due: over', 'Task|Schedule')"/>
                <xsl:text>)</xsl:text>
              </xsl:when>
              <xsl:otherwise>
    <xsl:text>
    (</xsl:text>
                <xsl:value-of select="gsa:i18n ('Next due', 'Task|Schedule')"/>: <xsl:value-of select="gsa:long-time (schedule/next_time)"/>
                <xsl:choose>
                  <xsl:when test="schedule_periods = 1">
                    <xsl:value-of select="concat (', ', gsa:i18n ('Once'))"/>
                  </xsl:when>
                  <xsl:when test="schedule_periods &gt; 1">
                    <xsl:value-of select="concat (', ', schedule_periods, ' ', gsa:i18n ('more times'))"/>
                  </xsl:when>
                  <xsl:otherwise>
                  </xsl:otherwise>
                </xsl:choose>
                <xsl:text>)</xsl:text>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <a href="/omp?cmd=get_schedule&amp;schedule_id={schedule/@id}&amp;token={/envelope/token}"
             class="icon icon-sm"
             title="{concat (gsa:view_details_title ('schedule', schedule/name), $next_due_string)}">
            <img src="/img/scheduled.svg" alt="{gsa:i18n ('Schedule Details')}"/>
          </a>
        </xsl:otherwise>
      </xsl:choose>
      <xsl:if test="boolean ($show-start-when-scheduled)">
        <xsl:choose>
          <xsl:when test="status!='Running' and status!='Stop Requested' and status!='Delete Requested' and status!='Ultimate Delete Requested' and status!='Resume Requested' and status!='Requested'">
            <xsl:call-template name="start-icon">
              <xsl:with-param name="type">task</xsl:with-param>
              <xsl:with-param name="id" select="@id"/>
              <xsl:with-param name="params">
                <input type="hidden" name="filter" value="{gsa:envelope-filter ()}"/>
                <input type="hidden" name="filt_id" value="{/envelope/params/filt_id}"/>
                <input type="hidden" name="next" value="{$next}"/>
              </xsl:with-param>
            </xsl:call-template>
          </xsl:when>
          <xsl:when test="status='Running'">
          </xsl:when>
          <xsl:otherwise>
            <img class="icon icon-sm" src="/img/start_inactive.svg" alt="{gsa:i18n ('Start', 'Action Verb')}" title="{gsa:i18n ('Task is already active')}"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>
    </xsl:when>
    <xsl:when test="status='Running'">
      <xsl:call-template name="stop-icon">
        <xsl:with-param name="type">task</xsl:with-param>
        <xsl:with-param name="id" select="@id"/>
        <xsl:with-param name="params">
          <input type="hidden" name="filter" value="{gsa:envelope-filter ()}"/>
          <input type="hidden" name="filt_id" value="{/envelope/params/filt_id}"/>
          <input type="hidden" name="next" value="{$next}"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="status='Stop Requested' or status='Delete Requested' or status='Ultimate Delete Requested' or status='Resume Requested' or status='Requested'">
      <img class="icon icon-sm" src="/img/start_inactive.svg" alt="{gsa:i18n ('Start', 'Action Verb')}" title="{gsa:i18n ('Task is already active')}"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="start-icon">
        <xsl:with-param name="type">task</xsl:with-param>
        <xsl:with-param name="id" select="@id"/>
        <xsl:with-param name="params">
          <input type="hidden" name="filter" value="{gsa:envelope-filter ()}"/>
          <input type="hidden" name="filt_id" value="{/envelope/params/filt_id}"/>
          <input type="hidden" name="next" value="{$next}"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:choose>
    <xsl:when test="(string-length (/envelope/params/enable_stop) &gt; 0 and /envelope/params/enable_stop = 1) or (boolean ($show-stop-when-scheduled) and status='Running' and string-length(schedule/@id) &gt; 0)">
      <xsl:call-template name="stop-icon">
        <xsl:with-param name="type">task</xsl:with-param>
        <xsl:with-param name="id" select="@id"/>
        <xsl:with-param name="params">
          <input type="hidden" name="filter" value="{gsa:envelope-filter ()}"/>
          <input type="hidden" name="filt_id" value="{/envelope/params/filt_id}"/>
          <input type="hidden" name="next" value="{$next}"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
  </xsl:choose>
  <xsl:choose>
    <xsl:when test="target/@id = ''">
      <img src="/img/resume_inactive.svg" alt="{gsa:i18n ('Resume')}" title="{gsa:i18n ('Task is a container')}"
         class="icon icon-sm"/>
    </xsl:when>
    <xsl:when test="(string-length(schedule/@id) &gt; 0) and not($enable-resume-when-scheduled)">
      <img src="/img/resume_inactive.svg" alt="{gsa:i18n ('Resume')}" title="{gsa:i18n ('Task is scheduled')}"
           class="icon icon-sm"/>
    </xsl:when>
    <xsl:when test="status='Stopped'">
      <xsl:choose>
        <xsl:when test="gsa:may ('resume_task') = 0">
          <img src="/img/resume_inactive.svg" alt="{gsa:i18n ('Resume')}" title="{gsa:i18n ('Permission to resume task denied')}"
             class="icon icon-sm"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="resume-icon">
            <xsl:with-param name="type">task</xsl:with-param>
            <xsl:with-param name="cmd">resume_task</xsl:with-param>
            <xsl:with-param name="id" select="@id"/>
            <xsl:with-param name="params">
              <input type="hidden" name="filter" value="{gsa:envelope-filter ()}"/>
              <input type="hidden" name="filt_id" value="{/envelope/params/filt_id}"/>
              <input type="hidden" name="next" value="{$next}"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <img src="/img/resume_inactive.svg" alt="{gsa:i18n ('Resume')}" title="{gsa:i18n ('Task is not stopped')}"
           class="icon icon-sm"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template name="move_task_icon">
  <xsl:param name="task" select="."/>
  <xsl:param name="slaves" select="../../../get_scanners_response/scanner[type=4]"/>
  <xsl:param name="next" select="'get_task'"/>
  <xsl:variable name="current_slave_id" select="$task/scanner/@id"/>
  <xsl:choose>
    <xsl:when test="gsa:may-op ('get_scanners') and gsa:may-op ('modify_task') and count ($slaves)">
      <span class="icon-menu">
        <xsl:variable name="slave_count" select="count ($slaves [@id != $current_slave_id])"/>
        <img src="/img/wizard.svg" class="icon icon-sm"/>
        <ul>
          <xsl:if test="$current_slave_id != '08b69003-5fc2-4037-a479-93b440211c73'">
            <xsl:variable name="class">
              <xsl:text>first</xsl:text>
              <xsl:if test="$slave_count = 0"> last</xsl:if>
            </xsl:variable>
            <li class="{$class}">
              <a href="#" class="{$class}" onclick="move_task_form.submit();">
                <xsl:value-of select="gsa:i18n ('Move to Master', 'Task')"/>
              </a>
            </li>
          </xsl:if>

          <xsl:for-each select="$slaves [@id != $current_slave_id]">
            <xsl:variable name="class">
              <xsl:choose>
                <xsl:when test="$slave_count = 1 and $current_slave_id = ''">first last</xsl:when>
                <xsl:when test="position () = 1 and $current_slave_id = ''">first</xsl:when>
                <xsl:when test="position () = last ()">last</xsl:when>
              </xsl:choose>
            </xsl:variable>
            <li class="{$class}">
              <a href="#" class="{$class}" onclick="move_task_form.slave_id.value = '{@id}'; move_task_form.submit();">
                <xsl:value-of select="gsa-i18n:strformat (gsa:i18n ('Move to Slave &quot;%1&quot;', 'Task'), name)"/>
              </a>
            </li>
          </xsl:for-each>
        </ul>
      </span>
      <form style="display:none" method="post" name="move_task_form" action="">
        <input type="hidden" name="token" value="{/envelope/token}"/>
        <input type="hidden" name="cmd" value="move_task"/>
        <input type="hidden" name="task_id" value="{$task/@id}"/>
        <input type="hidden" name="slave_id" value=""/>
        <input type="hidden" name="next" value="{$next}"/>
        <input type="hidden" name="filter" value="{/envelope/params/filter}"/>
        <input type="hidden" name="filt_id" value="{/envelope/params/filt_id}"/>
      </form>
    </xsl:when>
  </xsl:choose>
</xsl:template>

<xsl:template match="task" mode="details">
  <xsl:variable name="apply-overrides" select="../apply_overrides"/>
  <xsl:variable name="min-qod" select="/envelope/params/min_qod"/>

  <div class="toolbar">
    <xsl:call-template name="details-header-icons">
      <xsl:with-param name="cap-type" select="'Task'"/>
      <xsl:with-param name="type" select="'task'"/>
    </xsl:call-template>
    <xsl:choose>
      <xsl:when test="alterable = 0">
      </xsl:when>
      <xsl:otherwise>
        <img src="/img/alterable.svg" class="icon icon-sm"
             alt="{gsa:i18n ('This is an Alterable Task. Reports may not relate to current Scan Config or Target!')}"
             title="{gsa:i18n ('This is an Alterable Task. Reports may not relate to current Scan Config or Target!')}"/>
      </xsl:otherwise>
    </xsl:choose>
    <span class="divider"/>
    <xsl:call-template name="task-icons">
      <xsl:with-param name="next" select="'get_task'"/>
      <xsl:with-param name="enable-resume-when-scheduled" select="1"/>
      <xsl:with-param name="show-start-when-scheduled" select="1"/>
      <xsl:with-param name="show-stop-when-scheduled" select="1"/>
    </xsl:call-template>
    <xsl:call-template name="move_task_icon"/>
  </div>

  <div class="section-header">
    <xsl:call-template name="minor-details"/>
    <h1>
      <a href="/ng/tasks"
         title="{gsa:i18n ('Tasks')}">
        <img class="icon icon-lg" src="/img/task.svg" alt="Tasks"/>
      </a>
      <xsl:value-of select="gsa:i18n ('Task')"/>:
      <xsl:value-of select="name"/>
      <xsl:text> </xsl:text>
    </h1>
  </div>

  <div class="section-box">
    <table>
      <tr>
        <td><b><xsl:value-of select="gsa:i18n ('Name')"/>:</b></td>
        <td><b><xsl:value-of select="name"/></b></td>
      </tr>
      <tr>
        <td><xsl:value-of select="gsa:i18n ('Comment')"/>:</td>
        <td><xsl:value-of select="comment"/></td>
      </tr>
      <tr>
        <td><xsl:value-of select="gsa:i18n ('Target')"/>:</td>
        <td>
          <xsl:choose>
            <xsl:when test="boolean (target/permissions) and count (target/permissions/permission) = 0">
              <xsl:value-of select="gsa:i18n('Unavailable')"/>
              <xsl:text> (</xsl:text>
              <xsl:value-of select="gsa:i18n ('Name')"/>
              <xsl:text>: </xsl:text>
              <xsl:value-of select="target/name"/>
              <xsl:text>, </xsl:text>
              <xsl:value-of select="gsa:i18n ('ID')"/>: <xsl:value-of select="target/@id"/>
              <xsl:text>)</xsl:text>
            </xsl:when>
            <xsl:otherwise>
              <a href="/omp?cmd=get_target&amp;target_id={target/@id}&amp;token={/envelope/token}">
                <xsl:value-of select="target/name"/>
              </a>
            </xsl:otherwise>
          </xsl:choose>
        </td>
      </tr>
      <xsl:if test="gsa:may-op ('get_alerts') or count (alert) &gt; 0">
        <tr>
          <td><xsl:value-of select="gsa:i18n ('Alerts')"/>:</td>
          <td>
            <xsl:for-each select="alert">
              <xsl:choose>
                <xsl:when test="boolean (permissions) and count (permissions/permission) = 0">
                  <xsl:value-of select="gsa:i18n('Unavailable')"/>
                  <xsl:text> (</xsl:text>
                  <xsl:value-of select="gsa:i18n ('Name')"/>
                  <xsl:text>: </xsl:text>
                  <xsl:value-of select="name"/>
                  <xsl:text>, </xsl:text>
                  <xsl:value-of select="gsa:i18n ('ID')"/>: <xsl:value-of select="@id"/>
                  <xsl:text>)</xsl:text>
                </xsl:when>
                <xsl:when test="gsa:may-op ('get_alerts')">
                  <a href="/omp?cmd=get_alert&amp;alert_id={@id}&amp;token={/envelope/token}">
                    <xsl:value-of select="name"/>
                  </a>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="name"/>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:if test="position() != last()">, </xsl:if>
            </xsl:for-each>
          </td>
        </tr>
      </xsl:if>
      <xsl:if test="gsa:may-op ('get_schedules') or boolean (schedule)">
        <tr>
          <td><xsl:value-of select="gsa:i18n ('Schedule')"/>:</td>
          <td>
            <xsl:if test="schedule">
              <xsl:choose>
                <xsl:when test="gsa:may-op ('get_schedules')">
                  <xsl:choose>
                    <xsl:when test="boolean (schedule/permissions) and count (schedule/permissions/permission) = 0">
                      <xsl:value-of select="gsa:i18n('Unavailable')"/>
                      <xsl:text> (</xsl:text>
                      <xsl:value-of select="gsa:i18n ('Name')"/>
                      <xsl:text>: </xsl:text>
                      <xsl:value-of select="schedule/name"/>
                      <xsl:text>, </xsl:text>
                      <xsl:value-of select="gsa:i18n ('ID')"/>: <xsl:value-of select="schedule/@id"/>
                      <xsl:text>)</xsl:text>
                    </xsl:when>
                    <xsl:otherwise>
                      <a href="/omp?cmd=get_schedule&amp;schedule_id={schedule/@id}&amp;token={/envelope/token}">
                        <xsl:value-of select="schedule/name"/>
                      </a>
                    </xsl:otherwise>
                  </xsl:choose>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="schedule/name"/>
                </xsl:otherwise>
              </xsl:choose>
              <xsl:choose>
                <xsl:when test="schedule/next_time = 'over'">
                  (<xsl:value-of select="gsa:i18n ('Next due: over', 'Task|Schedule')"/>)
                </xsl:when>
                <xsl:otherwise>
                  <xsl:text> (</xsl:text>
                  <xsl:value-of select="gsa:i18n ('Next due', 'Task|Schedule')"/>: <xsl:value-of select="gsa:long-time (schedule/next_time)"/>
                  <xsl:choose>
                    <xsl:when test="schedule_periods = 1">
                      <xsl:value-of select="concat (', ', gsa:i18n ('Once'))"/>
                    </xsl:when>
                    <xsl:when test="schedule_periods &gt; 1">
                      <xsl:value-of select="concat (', ', schedule_periods, ' ', gsa:i18n ('more times'))"/>
                    </xsl:when>
                    <xsl:otherwise>
                    </xsl:otherwise>
                  </xsl:choose>
                  <xsl:text>)</xsl:text>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:if>
          </td>
        </tr>
      </xsl:if>
      <xsl:variable name="in_assets" select="preferences/preference[scanner_name='in_assets']"/>
      <xsl:if test="target/@id != ''">
        <tr>
          <td>
            <xsl:value-of select="gsa:i18n ('Add to Assets')"/>:
          </td>
          <td>
            <xsl:value-of select="gsa:i18n (normalize-space($in_assets/value), 'Task')"/>
          </td>
        </tr>
        <xsl:if test="normalize-space($in_assets/value) = 'yes'">
          <tr>
            <td></td>
            <td>
              <xsl:value-of select="gsa:i18n ('Apply Overrides')"/>:
              <xsl:value-of select="preferences/preference[scanner_name='assets_apply_overrides']/value"/>
            </td>
          </tr>
          <tr>
            <td></td>
            <td>
              <xsl:value-of select="gsa:i18n ('Min QoD')"/>:
              <xsl:value-of select="preferences/preference[scanner_name='assets_min_qod']/value"/>
              <xsl:text>%</xsl:text>
            </td>
          </tr>
        </xsl:if>
      </xsl:if>
      <tr>
        <td>
          <xsl:value-of select="gsa:i18n ('Alterable Task')"/>:
        </td>
        <td>
          <xsl:variable name="yes" select="alterable"/>
          <xsl:choose>
            <xsl:when test="string-length ($yes) = 0 or $yes = 0">
              <xsl:value-of select="gsa:i18n ('no')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="gsa:i18n ('yes')"/>
            </xsl:otherwise>
          </xsl:choose>
        </td>
      </tr>
      <tr>
        <xsl:variable name="auto_delete" select="preferences/preference[scanner_name='auto_delete']/value"/>
        <xsl:variable name="auto_delete_data" select="preferences/preference[scanner_name='auto_delete_data']/value"/>
        <td>
          <xsl:value-of select="gsa:i18n ('Auto Delete Reports')"/>:
        </td>
        <td>
          <xsl:choose>
            <xsl:when test="$auto_delete = 'keep'">
              <xsl:value-of select="gsa:i18n ('Automatically delete oldest reports but always keep newest ', 'Task|Auto Delete Reports')"/>
              <xsl:value-of select="$auto_delete_data"/>
              <xsl:value-of select="gsa:i18n (' reports', 'Task|Auto Delete Reports')"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="gsa:i18n ('Do not automatically delete reports')"/>
            </xsl:otherwise>
          </xsl:choose>
        </td>
      </tr>
      <xsl:if test="target/@id != ''">
        <tr>
          <td><xsl:value-of select="gsa:i18n ('Scanner')"/>:</td>
          <td>
            <xsl:choose>
              <xsl:when test="boolean (scanner/permissions) and count (scanner/permissions/permission) = 0">
                <xsl:value-of select="gsa:i18n('Unavailable')"/>
                <xsl:text> (</xsl:text>
                <xsl:value-of select="gsa:i18n ('Name')"/>
                <xsl:text>: </xsl:text>
                <xsl:value-of select="scanner/name"/>
                <xsl:text>, </xsl:text>
                <xsl:value-of select="gsa:i18n ('ID')"/>: <xsl:value-of select="scanner/@id"/>
                <xsl:text>)</xsl:text>
              </xsl:when>
              <xsl:otherwise>
                <xsl:choose>
                  <xsl:when test="gsa:may-op ('get_scanners')">
                    <a href="/omp?cmd=get_scanner&amp;scanner_id={scanner/@id}&amp;token={/envelope/token}">
                      <xsl:value-of select="scanner/name"/>
                    </a>
                    (<xsl:value-of select="gsa:i18n ('Type')"/>:
                    <xsl:call-template name="scanner-type-name">
                      <xsl:with-param name="type" select="scanner/type"/>
                    </xsl:call-template>)
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:value-of select="scanner/name"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:otherwise>
            </xsl:choose>
          </td>
        </tr>
        <xsl:if test="string-length (config/@id) &gt; 0">
          <tr>
            <td></td>
            <td>
              <xsl:value-of select="gsa:i18n ('Scan Config')"/>:
              <xsl:choose>
                <xsl:when test="boolean (config/permissions) and count (config/permissions/permission) = 0">
                  <xsl:value-of select="gsa:i18n('Unavailable')"/>
                  <xsl:text> (</xsl:text>
                  <xsl:value-of select="gsa:i18n ('Name')"/>
                  <xsl:text>: </xsl:text>
                  <xsl:value-of select="config/name"/>
                  <xsl:text>, </xsl:text>
                  <xsl:value-of select="gsa:i18n ('ID')"/>: <xsl:value-of select="config/@id"/>
                  <xsl:text>)</xsl:text>
                </xsl:when>
                <xsl:otherwise>
                  <a href="/omp?cmd=get_config&amp;config_id={config/@id}&amp;token={/envelope/token}">
                    <xsl:value-of select="config/name"/>
                  </a>
                </xsl:otherwise>
              </xsl:choose>
            </td>
          </tr>
        </xsl:if>
        <xsl:if test="config/type = 0">
          <tr>
            <td></td>
            <td>
              <xsl:value-of select="gsa:i18n ('Order for target hosts')"/>:
              <xsl:choose>
                <xsl:when test="hosts_ordering = 'sequential'"><xsl:value-of select="gsa:i18n ('Sequential', 'Task|Hosts Ordering')"/></xsl:when>
                <xsl:when test="hosts_ordering = 'random'"><xsl:value-of select="gsa:i18n ('Random', 'Task|Hosts Ordering')"/></xsl:when>
                <xsl:when test="hosts_ordering = 'reverse'"><xsl:value-of select="gsa:i18n ('Reverse', 'Task|Hosts Ordering')"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="gsa:i18n ('N/A')"/></xsl:otherwise>
              </xsl:choose>
            </td>
          </tr>
          <tr>
            <td></td>
            <td>
              <xsl:value-of select="gsa:i18n ('Network Source Interface')"/>:
              <xsl:value-of select="preferences/preference[scanner_name='source_iface']/value"/>
            </td>
          </tr>
          <tr>
            <td></td>
            <td>
              <xsl:value-of select="gsa:i18n (normalize-space (preferences/preference[scanner_name='max_checks']/name), 'Task')"/>:
              <xsl:value-of select="preferences/preference[scanner_name='max_checks']/value"/>
            </td>
          </tr>
          <tr>
            <td></td>
            <td>
              <xsl:value-of select="gsa:i18n (normalize-space (preferences/preference[scanner_name='max_hosts']/name), 'Task')"/>:
              <xsl:value-of select="preferences/preference[scanner_name='max_hosts']/value"/>
            </td>
          </tr>
        </xsl:if>
      </xsl:if>
      <tr>
        <td><xsl:value-of select="gsa:i18n ('Status')"/>:</td>
        <td>
          <xsl:call-template name="status_bar">
            <xsl:with-param name="status">
              <xsl:choose>
                <xsl:when test="target/@id='' and status='Running'">
                  <xsl:value-of select="'Uploading'"/>
                </xsl:when>
                <xsl:when test="target/@id=''">
                  <xsl:value-of select="'Container'"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="status"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:with-param>
            <xsl:with-param name="progress">
              <xsl:value-of select="progress/text()"/>
            </xsl:with-param>
          </xsl:call-template>
        </td>
      </tr>
      <tr>
        <td><xsl:value-of select="gsa:i18n ('Duration of last scan')"/>:</td>
        <td>
          <xsl:choose>
            <xsl:when test="last_report/report/scan_end">
              <xsl:value-of select="gsa:date-diff (last_report/report/scan_start, last_report/report/scan_end)"/>
            </xsl:when>
          </xsl:choose>
        </td>
      </tr>
      <tr>
        <td><xsl:value-of select="gsa:i18n ('Average scan duration')"/>:</td>
        <td>
          <xsl:value-of select="gsa:date-diff-text (date:duration (average_duration))"/>
        </td>
      </tr>
      <tr>
        <td>
          <xsl:value-of select="gsa:i18n ('Reports')"/>:
        </td>
        <td>
          <a href="/omp?cmd=get_reports&amp;replace_task_id=1&amp;filt_id=-2&amp;filter=task_id={@id} apply_overrides={$apply-overrides} min_qod={$min-qod} sort-reverse=date&amp;task_filt_id={/envelope/params/filt_id}&amp;token={/envelope/token}"
             title="{gsa-i18n:strformat (gsa:i18n ('Reports on Task %1'), name)}">
            <xsl:value-of select="report_count/text ()"/>
          </a>
          <xsl:if test="current_report/report/timestamp">
            <xsl:value-of select="concat(', ', gsa:i18n ('Current', 'Task|Report'), ': ')"/>
            <a href="/omp?cmd=get_report&amp;report_id={current_report/report/@id}&amp;overrides={$apply-overrides}&amp;;min_qod={$min-qod}&amp;token={/envelope/token}">
              <xsl:call-template name="short_timestamp_current"/>
            </a>
          </xsl:if>
           <xsl:value-of select="concat(' (', gsa:i18n ('Finished', 'Task|Reports'), ': ')"/>
           <a href="/omp?cmd=get_reports&amp;replace_task_id=1&amp;filt_id=-2&amp;filter=task_id={@id} and status=Done apply_overrides={$apply-overrides} min_qod={$min-qod} sort-reverse=date&amp;task_filt_id={/envelope/params/filt_id}&amp;token={/envelope/token}"
             title="{gsa-i18n:strformat (gsa:i18n ('Reports on Task %1'), name)}">
            <xsl:value-of select="report_count/finished"/>
           </a>
           <xsl:if test="last_report/report/timestamp">
             <xsl:value-of select="concat(', ', gsa:i18n ('Last', 'Task|Report'), ': ')"/>
             <a href="/omp?cmd=get_report&amp;report_id={last_report/report/@id}&amp;overrides={$apply-overrides}&amp;min_qod={$min-qod}&amp;token={/envelope/token}">
               <xsl:call-template name="short_timestamp_last"/>
             </a>
           </xsl:if>)
        </td>
      </tr>
      <tr>
        <td>
          <xsl:value-of select="gsa:i18n ('Results')"/>:
        </td>
        <td>
          <a href="/ng/results?filter=severity&gt;Error and task_id={@id} sort=nvt&amp;filt_id={/envelope/params/filt_id}"
             title="{gsa-i18n:strformat (gsa:i18n ('Results on Task %1'), name)}">
            <xsl:value-of select="result_count/text ()"/>
          </a>
        </td>
      </tr>
      <tr>
        <td>
          <xsl:value-of select="gsa:i18n ('Notes')"/>:
        </td>
        <td>
          <a href="/ng/notes?filter=task_id={@id} sort=nvt&amp;filt_id={/envelope/params/filt_id}"
             title="{gsa-i18n:strformat (gsa:i18n ('Notes on Task %1'), name)}">
            <xsl:value-of select="count (../../get_notes_response/note)"/>
          </a>
        </td>
      </tr>
      <tr>
        <td>
          <xsl:value-of select="gsa:i18n ('Overrides')"/>:
        </td>
        <td>
          <a href="/ng/overrides?filter=task_id={@id}&amp;filt_id={/envelope/params/filt_id}"
             title="{gsa-i18n:strformat (gsa:i18n ('Overrides on Task %1'), name)}">
            <xsl:value-of select="count (../../get_overrides_response/override)"/>
          </a>
        </td>
      </tr>
    </table>
  </div>

  <xsl:call-template name="user-tags-window">
    <xsl:with-param name="resource_type" select="'task'"/>
    <xsl:with-param name="tag_names" select="../../../get_tags_response"/>
  </xsl:call-template>

  <xsl:call-template name="resource-permissions-window">
    <xsl:with-param name="resource_type" select="'task'"/>
    <xsl:with-param name="permissions" select="../../../permissions/get_permissions_response"/>
    <xsl:with-param name="related">
      <xsl:variable name="detailed_target" select="../../../get_targets_response/target"/>
      <xsl:variable name="detailed_alerts" select="../../../get_alerts_response/alert"/>
      <xsl:if test="target/@id != ''">
        <target id="{target/@id}"/>
        <xsl:if test="$detailed_target/ssh_credential/@id != ''">
          <credential id="{$detailed_target/ssh_credential/@id}"/>
        </xsl:if>
        <xsl:if test="$detailed_target/smb_credential/@id != '' and $detailed_target/smb_credential/@id != $detailed_target/ssh_credential/@id">
          <credential id="{$detailed_target/smb_credential/@id}"/>
        </xsl:if>
        <xsl:if test="$detailed_target/esxi_credential/@id != '' and $detailed_target/esxi_credential/@id != $detailed_target/ssh_credential/@id and $detailed_target/esxi_credential/@id != $detailed_target/smb_credential/@id">
          <credential id="{$detailed_target/esxi_credential/@id}"/>
        </xsl:if>
        <xsl:if test="$detailed_target/snmp_credential/@id != '' and $detailed_target/snmp_credential/@id != $detailed_target/ssh_credential/@id and $detailed_target/snmp_credential/@id != $detailed_target/smb_credential/@id and $detailed_target/snmp_credential/@id != $detailed_target/esxi_credential/@id">
          <credential id="{$detailed_target/snmp_credential/@id}"/>
        </xsl:if>
        <xsl:if test="$detailed_target/port_list/@id != ''">
          <port_list id="{$detailed_target/port_list/@id}"/>
        </xsl:if>
      </xsl:if>
      <xsl:for-each select="alert">
        <xsl:if test="@id != ''">
          <xsl:variable name="alert_id" select="@id"/>
          <alert id="{$alert_id}"/>
          <xsl:if test="$detailed_alerts[@id=$alert_id]/filter/@id != ''">
            <filter id="{$detailed_alerts[@id=$alert_id]/filter/@id}"/>
          </xsl:if>
        </xsl:if>
      </xsl:for-each>
      <xsl:if test="config/@id != ''">
        <config id="{config/@id}"/>
      </xsl:if>
      <xsl:if test="scanner/@id != ''">
        <scanner id="{scanner/@id}"/>
      </xsl:if>
      <xsl:if test="schedule/@id != ''">
        <schedule id="{schedule/@id}"/>
      </xsl:if>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="short_timestamp_first">
  <xsl:if test="first_report/report/timestamp">
    <xsl:value-of select="concat (date:month-abbreviation(first_report/report/timestamp), ' ', date:day-in-month(first_report/report/timestamp), ' ', date:year(first_report/report/timestamp))"/>
  </xsl:if>
</xsl:template>

<xsl:template name="short_timestamp_last">
  <xsl:if test="last_report/report/timestamp">
    <xsl:value-of select="concat (date:month-abbreviation(last_report/report/timestamp), ' ', date:day-in-month(last_report/report/timestamp), ' ', date:year(last_report/report/timestamp))"/>
  </xsl:if>
</xsl:template>

<xsl:template name="short_timestamp_second_last">
  <xsl:if test="first_report/report/timestamp">
    <xsl:value-of select="concat (date:month-abbreviation(second_last_report/report/timestamp), ' ', date:day-in-month(second_last_report/report/timestamp), ' ', date:year(second_last_report/report/timestamp))"/>
  </xsl:if>
</xsl:template>

<xsl:template name="short_timestamp_current">
  <xsl:if test="current_report/report/timestamp">
    <xsl:value-of select="concat (date:month-abbreviation(current_report/report/timestamp), ' ', date:day-in-month(current_report/report/timestamp), ' ', date:year(current_report/report/timestamp))"/>
  </xsl:if>
</xsl:template>

<!-- TREND METER -->
<xsl:template name="trend_meter">
  <xsl:choose>
    <xsl:when test="trend = 'up'">
      <img src="/img/trend_up.svg" alt="{gsa:i18n ('Severity increased')}"
        class="icon icon-sm"
        title="{gsa:i18n ('Severity increased')}"/>
    </xsl:when>
    <xsl:when test="trend = 'down'">
      <img src="/img/trend_down.svg" alt="{gsa:i18n ('Severity decreased')}"
        class="icon icon-sm"
        title="{gsa:i18n ('Severity decreased')}"/>
    </xsl:when>
    <xsl:when test="trend = 'more'">
      <img src="/img/trend_more.svg" alt="{gsa:i18n ('Vulnerability count increased')}"
        class="icon icon-sm"
        title="{gsa:i18n ('Vulnerability count increased')}"/>
    </xsl:when>
    <xsl:when test="trend = 'less'">
      <img src="/img/trend_less.svg" alt="{gsa:i18n ('Vulnerability count decreased')}"
        class="icon icon-sm"
        title="{gsa:i18n ('Vulnerability count decreased')}"/>
    </xsl:when>
    <xsl:when test="trend = 'same'">
      <img src="/img/trend_nochange.svg" alt="{gsa:i18n ('Vulnerabilities did not change')}"
        class="icon icon-sm"
        title="{gsa:i18n ('Vulnerabilities did not change')}"/>
    </xsl:when>
    <xsl:otherwise>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="target" mode="newtask">
  <option value="{@id}"><xsl:value-of select="name"/></option>
</xsl:template>

<xsl:template match="config" mode="newtask">
  <option value="{@id}"><xsl:value-of select="name"/></option>
</xsl:template>

<xsl:template match="alert" mode="newtask">
  <xsl:param name="select_id" select="''"/>
  <xsl:choose>
    <xsl:when test="@id = $select_id">
      <option value="{@id}" selected="1"><xsl:value-of select="name"/></option>
    </xsl:when>
    <xsl:otherwise>
      <option value="{@id}"><xsl:value-of select="name"/></option>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="group" mode="newtask">
  <option value="{@id}"><xsl:value-of select="name"/></option>
</xsl:template>

<xsl:template match="schedule" mode="newtask">
  <option value="{@id}"><xsl:value-of select="name"/></option>
</xsl:template>

<xsl:template name="status_bar">
  <xsl:param name="status">(Unknown)</xsl:param>
  <xsl:param name="progress">(Unknown)</xsl:param>
  <xsl:param name="title_suffix"></xsl:param>
  <xsl:choose>
    <xsl:when test="$status='Running'">
      <div class="progressbar_box" title="{gsa:i18n ($status, 'Status')}">
        <div class="progressbar_bar" style="width:{$progress}px;"></div>
        <div class="progressbar_text">
          <xsl:value-of select="$progress"/> %
        </div>
      </div>
    </xsl:when>
    <xsl:when test="$status='New'">
      <div class="progressbar_box" title="{gsa:i18n ($status, 'Status')}{$title_suffix}">
        <div class="progressbar_bar_new" style="width:100px;"></div>
        <div class="progressbar_text">
          <i><b><xsl:value-of select="gsa:i18n ($status, 'Status')"/></b></i>
        </div>
      </div>
    </xsl:when>
    <xsl:when test="$status='Requested'">
      <div class="progressbar_box" title="{gsa:i18n ($status, 'Status')}{$title_suffix}">
        <div class="progressbar_bar_request" style="width:100px;"></div>
        <div class="progressbar_text"><xsl:value-of select="gsa:i18n ($status, 'Status')"/></div>
      </div>
    </xsl:when>
    <xsl:when test="$status='Delete Requested'">
      <div class="progressbar_box" title="{gsa:i18n ($status, 'Status')}{$title_suffix}">
        <div class="progressbar_bar_request" style="width:100px;"></div>
        <div class="progressbar_text"><xsl:value-of select="gsa:i18n ($status, 'Status')"/></div>
      </div>
    </xsl:when>
    <xsl:when test="$status='Ultimate Delete Requested'">
      <div class="progressbar_box" title="{gsa:i18n ('Delete Requested', 'Status')}">
        <div class="progressbar_bar_request" style="width:100px;"></div>
        <div class="progressbar_text"><xsl:value-of select="gsa:i18n ('Delete Requested', 'Status')"/></div>
      </div>
    </xsl:when>
    <xsl:when test="$status='Resume Requested'">
      <div class="progressbar_box" title="{gsa:i18n ($status, 'Status')}{$title_suffix}">
        <div class="progressbar_bar_request" style="width:100px;"></div>
        <div class="progressbar_text"><xsl:value-of select="gsa:i18n ($status, 'Status')"/></div>
      </div>
    </xsl:when>
    <xsl:when test="$status='Stop Requested'">
      <div class="progressbar_box" title="{gsa:i18n ($status, 'Status')}{$title_suffix}">
        <div class="progressbar_bar_request" style="width:100px;"></div>
        <div class="progressbar_text"><xsl:value-of select="gsa:i18n ($status, 'Status')"/></div>
      </div>
    </xsl:when>
    <xsl:when test="$status='Stopped'">
      <div class="progressbar_box" title="{gsa:i18n ($status, 'Status')}{$title_suffix}">
        <div class="progressbar_bar_request" style="width:{$progress}px;"></div>
        <div class="progressbar_text">
          <xsl:value-of select="gsa:i18n ($status, 'Status')"/>
          <xsl:if test="$progress &gt;= 0">
            <xsl:value-of select="gsa:i18n (' at ', 'Status')"/> <xsl:value-of select="$progress"/> %
          </xsl:if>
        </div>
      </div>
    </xsl:when>
    <xsl:when test="$status='Internal Error'">
      <div class="progressbar_box" title="{gsa:i18n ($status, 'Status')}{$title_suffix}">
        <div class="progressbar_bar_error" style="width:100px;"></div>
        <div class="progressbar_text"><xsl:value-of select="gsa:i18n ($status, 'Status')"/></div>
      </div>
    </xsl:when>
    <xsl:when test="$status='Done'">
      <div class="progressbar_box" title="{gsa:i18n ($status, 'Status')}{$title_suffix}">
        <div class="progressbar_bar_done" style="width:100px;"></div>
        <div class="progressbar_text"><xsl:value-of select="gsa:i18n ($status, 'Status')"/></div>
      </div>
    </xsl:when>
    <xsl:when test="$status='Uploading'">
      <div class="progressbar_box" title="{gsa:i18n ($status, 'Status')}{$title_suffix}">
        <div class="progressbar_bar_done" style="width:{$progress}px;"></div>
        <div class="progressbar_text">
          <xsl:value-of select="gsa:i18n ($status, 'Status')"/>
          <xsl:if test="$progress &gt;= 0">
            <xsl:text>: </xsl:text>
            <xsl:value-of select="$progress"/> %
          </xsl:if>
        </div>
      </div>
    </xsl:when>
    <xsl:when test="$status='Container'">
      <div class="progressbar_box" title="{gsa:i18n ($status, 'Status')}{$title_suffix}">
        <div class="progressbar_bar_done" style="width:100px;"></div>
        <div class="progressbar_text"><xsl:value-of select="gsa:i18n ($status, 'Status')"/></div>
      </div>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="gsa:i18n ($status, 'Status')"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- BEGIN GENERIC MANAGEMENT -->

<xsl:template name="list-window">
  <xsl:param name="type"/>
  <xsl:param name="subtype"/>
  <xsl:param name="cap-type"/>
  <xsl:param name="cap-type-plural" select="concat ($cap-type, 's')"/>
  <xsl:param name="resources-summary"/>
  <xsl:param name="resources"/>
  <xsl:param name="count"/>
  <xsl:param name="filtered-count"/>
  <xsl:param name="full-count"/>
  <xsl:param name="columns"/>
  <xsl:param name="icon-count" select="8"/>
  <xsl:param name="new-icon" select="gsa:may-op (concat ('create_', $type))"/>
  <xsl:param name="upload-icon" select="false ()"/>
  <xsl:param name="default-filter"/>
  <xsl:param name="extra_params"/>
  <xsl:param name="extra_params_string">
    <xsl:for-each select="exslt:node-set($extra_params)/param">
      <xsl:text>&amp;</xsl:text>
      <xsl:value-of select="name"/>
      <xsl:text>=</xsl:text>
      <xsl:value-of select="value"/>
    </xsl:for-each>
  </xsl:param>
  <xsl:param name="no_bulk" select="0"/>
  <xsl:param name="top-visualization" select="''"/>

  <xsl:variable name="apply-overrides"
                select="filters/keywords/keyword[column='apply_overrides']/value"/>
  <xsl:variable name="subtype_param">
    <xsl:if test="$subtype != ''">
      <xsl:value-of select="concat ('&amp;', $type, '_type=', $subtype)"/>
    </xsl:if>
  </xsl:variable>

  <div class="toolbar row">
    <div class="col-4">
    <xsl:choose>
      <xsl:when test="$subtype != ''">
        <a href="/help/{gsa:type-many($subtype)}.html?token={/envelope/token}"
           class="icon icon-sm"
           title="{gsa:i18n ('Help')}: {gsa:i18n ($cap-type-plural)}">
          <img src="/img/help.svg"/>
        </a>
      </xsl:when>
      <xsl:otherwise>
        <a href="/help/{gsa:type-many($type)}.html?token={/envelope/token}"
           class="icon icon-sm"
           title="{gsa:i18n ('Help')}: {gsa:i18n ($cap-type-plural)}">
          <img src="/img/help.svg"/>
        </a>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="$type = 'report'"/>
      <xsl:when test="$type = 'info'"/>
      <xsl:when test="$new-icon and $subtype != ''">
        <!-- i18n with concat : see dynamic_strings.xsl - type-new -->
        <a href="/omp?cmd=new_{$subtype}{$extra_params_string}&amp;next=get_{$type}&amp;filter={str:encode-uri (filters/term, true ())}&amp;filt_id={/envelope/params/filt_id}&amp;token={/envelope/token}"
           class="new-action-icon icon icon-sm" data-type="{$subtype}" data-reload="window"
           title="{gsa:i18n (concat ('New ', $cap-type))}">
          <img src="/img/new.svg"/>
        </a>
      </xsl:when>
      <xsl:when test="$new-icon and $type = 'config'">
        <a href="/omp?cmd=new_{$type}{$extra_params_string}&amp;next=get_{$type}&amp;filter={str:encode-uri (filters/term, true ())}&amp;filt_id={/envelope/params/filt_id}&amp;token={/envelope/token}"
           class="new-action-icon icon icon-sm" data-type="{$type}" data-reload="dialog"
           data-dialog-id="create_new_{$type}"
           title="{gsa:i18n (concat ('New ', $cap-type))}">
           <span class="success-dialog" data-type="{$type}" data-cmd="edit_{$type}"
             data-reload="window" data-close-reload="window"/>
          <img src="/img/new.svg"/>
        </a>
      </xsl:when>
      <xsl:when test="$new-icon">
        <!-- i18n with concat : see dynamic_strings.xsl - type-new -->
        <a href="/omp?cmd=new_{$type}{$extra_params_string}&amp;next=get_{$type}&amp;filter={str:encode-uri (filters/term, true ())}&amp;filt_id={/envelope/params/filt_id}&amp;token={/envelope/token}"
           data-dialog-id="create_new_{$type}"
           class="new-action-icon icon icon-sm" data-type="{$type}" data-reload="window"
           title="{gsa:i18n (concat ('New ', $cap-type))}">
          <img src="/img/new.svg"/>
        </a>
      </xsl:when>
    </xsl:choose>
    <xsl:choose>
      <xsl:when test="$upload-icon">
        <!-- i18n with concat : see dynamic_strings.xsl - type-upload -->
        <a href="/omp?cmd=upload_{$type}{$extra_params_string}&amp;next=get_{$type}&amp;filter={str:encode-uri (filters/term, true ())}&amp;filt_id={/envelope/params/filt_id}&amp;token={/envelope/token}"
           class="upload-action-icon icon icon-sm" data-type="{$type}"
           data-dialog-id="upload_{$type}"
           title="{gsa:i18n (concat ('Import ', $cap-type))}">
          <img src="/img/upload.svg"/>
        </a>
      </xsl:when>
    </xsl:choose>
    </div>

    <div id="list-window-filter" class="col-8">
      <xsl:call-template name="filter-window-part">
        <xsl:with-param name="type" select="$type"/>
        <xsl:with-param name="subtype" select="$subtype"/>
        <xsl:with-param name="list" select="$resources-summary"/>
        <xsl:with-param name="full-count" select="$full-count"/>
        <xsl:with-param name="columns" select="$columns" xmlns=""/>
        <xsl:with-param name="filter_options" xmlns="">
          <xsl:if test="$type='result' or $type='report' or $type='task'">
            <option>apply_overrides</option>
            <option>min_qod</option>
          </xsl:if>
          <xsl:if test="$type='result'">
            <option>autofp</option>
            <option>levels</option>
          </xsl:if>
          <option>first</option>
          <option>rows</option>
        </xsl:with-param>
        <xsl:with-param name="extra_params" xmlns="">
          <xsl:copy-of select="$extra_params"/>
          <xsl:if test="$subtype != ''">
            <param>
              <name><xsl:value-of select="$type"/>_type</name>
              <value><xsl:value-of select="$subtype"/></value>
            </param>
          </xsl:if>
        </xsl:with-param>
      </xsl:call-template>
    </div>
  </div>

  <div id="list-window-header">
    <div class="section-header">
      <h1>
        <xsl:choose>
          <xsl:when test="$type = 'vuln'">
            <img class="icon icon-lg" src="/img/vulnerability.svg"/>
          </xsl:when>
          <xsl:when test="$subtype != ''">
            <img class="icon icon-lg" src="/img/{$subtype}.svg"/>
          </xsl:when>
          <xsl:otherwise>
            <img class="icon icon-lg" src="/img/{$type}.svg"/>
          </xsl:otherwise>
        </xsl:choose>

        <xsl:value-of select="gsa:i18n ($cap-type-plural)"/>
        (<xsl:value-of select="gsa-i18n:strformat (gsa:i18n ('%1 of %2'), $filtered-count, $full-count)"/>)
      </h1>

      <xsl:if test="$top-visualization != ''">
        <div class="dashboard-controls" id="top-dashboard-controls"/>
      </xsl:if>
    </div>
  </div>

  <xsl:if test="$top-visualization != ''">
    <div id="top-dashboard-section" class="section-box">
      <xsl:copy-of select="$top-visualization"/>
    </div>
  </xsl:if>

  <div class="section-box resources" id="table-box">
    <div class="header">
      <xsl:call-template name="filter-window-pager">
        <xsl:with-param name="type" select="$type"/>
        <xsl:with-param name="list" select="$resources-summary"/>
        <xsl:with-param name="count" select="$count"/>
        <xsl:with-param name="filtered_count" select="$filtered-count"/>
        <xsl:with-param name="full_count" select="$full-count"/>
        <xsl:with-param name="extra_params" select="concat($subtype_param, $extra_params_string)"/>
      </xsl:call-template>
    </div>

      <!-- The entire table of resources, in a variable. -->
      <xsl:variable name="table">
        <table class="gbntable">

          <!-- Column headings, top row. -->
          <tr class="gbntablehead2">
            <xsl:variable name="current" select="."/>
            <xsl:variable name="token" select="/envelope/token"/>
            <!-- Generate given column headings. -->
            <xsl:for-each select="exslt:node-set ($columns)/column">
              <xsl:choose>
                <xsl:when test="boolean (hide_in_table)"/>
                <xsl:when test="count (column) = 0 and field != ''">
                  <!-- Single column. -->
                  <td rowspan="2">
                    <xsl:copy-of select="html/before/*"/>
                    <xsl:call-template name="column-name">
                      <xsl:with-param name="head" select="name"/>
                      <xsl:with-param name="image" select="image"/>
                      <xsl:with-param name="name" select="field"/>
                      <xsl:with-param name="type" select="$type"/>
                      <xsl:with-param name="current" select="$current"/>
                      <xsl:with-param name="token" select="$token"/>
                      <xsl:with-param name="extra_params" select="concat($subtype_param, $extra_params_string)"/>
                      <xsl:with-param name="sort-reverse" select="boolean (sort-reverse)"/>
                      <xsl:with-param name="i18n-context" select="$cap-type"/>
                    </xsl:call-template>
                    <xsl:copy-of select="html/after/*"/>
                  </td>
                </xsl:when>
                <xsl:when test="count (column) = 0">
                  <!-- Single column without a sort field. -->
                  <td rowspan="2">
                    <xsl:copy-of select="html/before/*"/>
                    <!-- FIXME : Test if translated name is given everywhere -->
                    <xsl:value-of select="name"/>
                    <xsl:copy-of select="html/after/*"/>
                  </td>
                </xsl:when>
                <xsl:otherwise>
                  <!-- Column with subcolumns. -->
                  <td colspan="{count (column)}">
                    <xsl:copy-of select="html/before/*"/>
                    <!-- FIXME : Test if translated name is given everywhere -->
                    <xsl:value-of select="name"/>
                    <xsl:copy-of select="html/after/*"/>
                  </td>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
            <!-- Action column. -->
            <xsl:if test="$icon-count &gt; 0">
              <td style="width: {gsa:actions-width ($icon-count)}px" rowspan="2"><xsl:value-of select="gsa:i18n ('Actions')"/></td>
            </xsl:if>
          </tr>

          <!-- Column headings, second row. -->
          <tr class="gbntablehead2">
            <xsl:variable name="current" select="."/>
            <xsl:variable name="token" select="/envelope/token"/>
            <xsl:for-each select="exslt:node-set ($columns)/column">
              <xsl:choose>
                <xsl:when test="count (column) = 0">
                  <!-- Single column.  Done in top row. -->
                </xsl:when>
                <xsl:otherwise>
                  <!-- Column with subcolumns.  Output the subcolumns. -->
                  <xsl:for-each select="column">
                    <td style="font-size:10px;">
                      <xsl:copy-of select="html/before/*"/>
                      <xsl:call-template name="column-name">
                        <xsl:with-param name="head" select="name"/>
                        <xsl:with-param name="image" select="image"/>
                        <xsl:with-param name="name" select="field"/>
                        <xsl:with-param name="type" select="$type"/>
                        <xsl:with-param name="current" select="$current"/>
                        <xsl:with-param name="token" select="$token"/>
                        <xsl:with-param name="extra_params" select="concat($subtype_param, $extra_params_string)"/>
                        <xsl:with-param name="sort-reverse" select="boolean (sort-reverse)"/>
                        <xsl:with-param name="i18n-context" select="$cap-type"/>
                      </xsl:call-template>
                      <xsl:copy-of select="html/after/*"/>
                    </td>
                  </xsl:for-each>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:for-each>
          </tr>

          <!-- A nested variable: Form inputs for the bulk icons. -->
          <xsl:variable name="bulk-elements">
            <xsl:variable name="selection_type">
              <xsl:choose>
                <xsl:when test="/envelope/params/bulk_select = 1">selection</xsl:when>
                <xsl:when test="/envelope/params/bulk_select = 2">all filtered</xsl:when>
                <xsl:otherwise>page contents</xsl:otherwise>
              </xsl:choose>
            </xsl:variable>
            <input type="hidden" name="token" value="{/envelope/token}"/>
            <xsl:text> </xsl:text>
            <input type="hidden" name="cmd" value="process_bulk"/>
            <input type="hidden" name="next" value="get_{$type}s"/>
            <input type="hidden" name="filter" value="{filters/term}"/>
            <input type="hidden" name="filt_id" value="{filters/@id}"/>
            <input type="hidden" name="bulk_select" value="{/envelope/params/bulk_select}"/>
            <xsl:if test="$subtype">
              <input type="hidden" name="{$type}_type" value="{$subtype}"/>
            </xsl:if>

            <xsl:for-each select="exslt:node-set($extra_params)/param">
              <input type="hidden" name="{name}" value="{value}"/>
            </xsl:for-each>

            <input type="hidden" name="resource_type" value="{$type}"/>

            <!-- i18n with concat : see dynamic_strings.xsl - bulk-actions -->
            <xsl:if test="gsa:may-op (concat ('delete_', $type)) and ($type != 'info' and $type != 'user' and $type != 'report' and $type != 'asset')">
              <input type="image" class="icon icon-sm bulk-dialog-icon" data-type="{$type}" name="bulk_trash" title="{gsa:i18n (concat ('Move ', $selection_type, ' to trashcan'))}" src="/img/trashcan.svg"/>
            </xsl:if>
            <xsl:if test="gsa:may-op (concat ('delete_', $type)) and ($type = 'user' or $type = 'report' or $type = 'asset')">
              <input type="image" class="icon icon-sm bulk-dialog-icon" data-type="{$type}" name="bulk_delete" title="{gsa:i18n (concat ('Delete ', $selection_type))}" src="/img/delete.svg"/>
            </xsl:if>
            <xsl:if test="$type = 'asset' and $subtype = 'host' and gsa:may-op ('create_target')">
              <input type="image" class="icon icon-sm bulk-dialog-icon" data-type="{$type}" name="bulk_create" title="{gsa:i18n (concat ('Create Target from ', $selection_type))}" src="/img/new.svg"/>
            </xsl:if>
            <xsl:if test="$type != 'report'">
              <input class="icon icon-sm" type="image" name="bulk_export" title="{gsa:i18n (concat ('Export ', $selection_type))}" src="/img/download.svg"/>
            </xsl:if>
          </xsl:variable>

          <!-- Resource rows, with extra row if bulk is enabled. -->
          <tbody>
            <xsl:apply-templates select="$resources"/>
          </tbody>
          <xsl:choose>
            <xsl:when test="$no_bulk">
            </xsl:when>
            <xsl:when test="not (/envelope/params/bulk_select = 1)">
              <!-- Bulk "Apply to page contents" or "Apply to all filtered". -->
              <tfoot>
                <tr>
                  <td colspan="{count (exslt:node-set ($columns)/column/column) + count (exslt:node-set ($columns)/column[count (column) = 0]) + ($icon-count &gt; 0)}"  style="text-align:right;" class="small_inline_form">
                    <form name="bulk-actions" method="post" action="/omp" enctype="multipart/form-data" class="small_inline_form">
                      <xsl:choose>
                        <xsl:when test="$type = 'asset' and ($subtype = 'host' or $subtype = 'os')">
                          <xsl:choose>
                            <xsl:when test="/envelope/params/bulk_select = 2">
                              <input type="hidden" name="{$subtype}_count" value="{$filtered-count}"/>
                            </xsl:when>
                            <xsl:otherwise>
                              <input type="hidden" name="{$subtype}_count" value="{$count}"/>
                            </xsl:otherwise>
                          </xsl:choose>
                          <xsl:for-each select="$resources">
                            <input type="hidden" name="bulk_selected:{../@id}" value="1"/>
                          </xsl:for-each>
                        </xsl:when>
                        <xsl:when test="$type = 'info'">
                          <xsl:for-each select="$resources">
                            <input type="hidden" name="bulk_selected:{../@id}" value="1"/>
                          </xsl:for-each>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:for-each select="$resources">
                            <input type="hidden" name="bulk_selected:{@id}" value="1"/>
                          </xsl:for-each>
                        </xsl:otherwise>
                      </xsl:choose>
                      <xsl:copy-of select="$bulk-elements"/>
                    </form>
                  </td>
                </tr>
              </tfoot>
            </xsl:when>
            <xsl:otherwise>
              <!-- Bulk "Apply to selection" (the page with checkboxes). -->
              <tfoot>
                <tr>
                  <td colspan="{count (exslt:node-set ($columns)/column/column) + count (exslt:node-set ($columns)/column[count (column) = 0]) + ($icon-count &gt; 0)}"  style="text-align:right;" class="small_inline_form">
                    <xsl:choose>
                      <xsl:when test="$type = 'asset' and ($subtype = 'host' and $subtype = 'os')">
                        <input type="hidden" name="{$subtype}_count" value="0"/>
                      </xsl:when>
                    </xsl:choose>
                    <xsl:copy-of select="$bulk-elements"/>
                  </td>
                </tr>
              </tfoot>
            </xsl:otherwise>
          </xsl:choose>
        </table>
      </xsl:variable>

      <!-- Output the table from the variable. -->
      <xsl:choose>
        <xsl:when test="/envelope/params/bulk_select = 1">
          <!-- Bulk "Apply to selection" (the page with checkboxes). -->
          <form name="bulk-actions" method="post" action="/omp" enctype="multipart/form-data">
            <xsl:copy-of select="$table"/>
          </form>
        </xsl:when>
        <xsl:otherwise>
          <xsl:copy-of select="$table"/>
        </xsl:otherwise>
      </xsl:choose>

      <!-- The bulk dropdown and refresh icon, during bulk selection. -->
      <xsl:if test="not ($no_bulk)">
        <form name="bulk_select_type_form" class="small_inline_form bulk-select-type">
          <input type="hidden" name="token" value="{/envelope/token}"/>
          <input type="hidden" name="cmd" value="get_{gsa:type-many($type)}"/>
          <xsl:if test="$subtype">
            <input type="hidden" name="{$type}_type" value="{$subtype}"/>
          </xsl:if>
          <xsl:for-each select="exslt:node-set($extra_params)/param">
            <input type="hidden" name="{name}" value="{value}"/>
          </xsl:for-each>
          <input type="hidden" name="filter" value="{filters/term}"/>
          <input type="hidden" name="filt_id" value="{filters/@id}"/>
          <select name="bulk_select" onchange="bulk_select_type_form.submit()">
            <!-- TODO selection by current parameter value + check marks -->
            <xsl:choose>
              <xsl:when test="not (/envelope/params/bulk_select != 0)">
                <option value="0" selected="1">&#8730;<xsl:value-of select="gsa:i18n('Apply to page contents')"/></option>
              </xsl:when>
              <xsl:otherwise>
                <option value="0"><xsl:value-of select="gsa:i18n('Apply to page contents')"/></option>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
              <xsl:when test="/envelope/params/bulk_select = '1'">
                <option value="1" selected="1">&#8730;<xsl:value-of select="gsa:i18n('Apply to selection')"/></option>
              </xsl:when>
              <xsl:otherwise>
                <option value="1"><xsl:value-of select="gsa:i18n('Apply to selection')"/></option>
              </xsl:otherwise>
            </xsl:choose>
            <xsl:choose>
              <xsl:when test="/envelope/params/bulk_select = '2'">
                <option value="2" selected="1">&#8730;<xsl:value-of select="gsa:i18n('Apply to all filtered')"/></option>
              </xsl:when>
              <xsl:otherwise>
                <option value="2"><xsl:value-of select="gsa:i18n('Apply to all filtered')"/></option>
              </xsl:otherwise>
            </xsl:choose>
          </select>
        </form>
      </xsl:if>

      <!-- Bottom line with applied filter and pager. -->
      <xsl:if test="string-length (filters/term) &gt; 0">
        <div class="footer">
          <div class="applied-filter">
            (<xsl:value-of select="gsa:i18n('Applied filter')"/>:
            <a href="/omp?cmd=get_{gsa:type-many($type)}{$extra_params_string}&amp;filter={str:encode-uri (filters/term, true ())}&amp;token={/envelope/token}">
              <xsl:value-of select="filters/term"/>
            </a>)
          </div>
          <xsl:call-template name="filter-window-pager">
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="list" select="$resources-summary"/>
            <xsl:with-param name="count" select="$count"/>
            <xsl:with-param name="filtered_count" select="$filtered-count"/>
            <xsl:with-param name="full_count" select="$full-count"/>
            <xsl:with-param name="extra_params" select="concat($subtype_param, $extra_params_string)"/>
          </xsl:call-template>
        </div>
      </xsl:if>

  </div> <!-- /table-box -->

</xsl:template>

<xsl:template name="minor-details">
  <div class="section-header-info">
    <table>
      <tr>
        <td><xsl:value-of select="gsa:i18n ('ID')"/>:</td>
        <td><xsl:value-of select="@id"/></td>
      </tr>
      <tr>
        <td><xsl:value-of select="gsa:i18n ('Created', 'Date')"/>:</td>
        <td><xsl:value-of select="gsa:long-time (creation_time)"/></td>
      </tr>
      <tr>
        <td><xsl:value-of select="gsa:i18n ('Modified', 'Date')"/>:</td>
        <td><xsl:value-of select="gsa:long-time (modification_time)"/></td>
      </tr>
      <tr>
        <td><xsl:value-of select="gsa:i18n ('Owner')"/>:</td>
        <td><xsl:value-of select="owner/name"/></td>
      </tr>
    </table>
  </div>
</xsl:template>

<xsl:template name="details-header-icons">
  <xsl:param name="cap-type"/>
  <xsl:param name="cap-type-plural" select="concat ($cap-type, 's')"/>
  <xsl:param name="type"/>
  <xsl:param name="noedit"/>
  <xsl:param name="nonew"/>
  <xsl:param name="noupload" select="true ()"/>
  <xsl:param name="noclone" select="$nonew"/>
  <xsl:param name="grey-clone" select="0"/>
  <xsl:param name="noexport"/>
  <xsl:param name="filter" select="/envelope/params/filter"/>
  <xsl:param name="filt_id" select="/envelope/params/filt_id"/>

  <!-- i18n with concat : see dynamic_strings.xsl - type-details -->
  <a class="icon icon-sm" href="/help/{$type}_details.html?token={/envelope/token}"
    title="{gsa:i18n ('Help')}: {gsa:i18n(concat($cap-type, ' Details'))}">
    <img src="/img/help.svg"/>
  </a>
  <xsl:choose>
    <xsl:when test="$nonew"/>
    <xsl:when test="gsa:may-op (concat ('create_', $type)) and $type = 'task'">
      <span class="icon-menu">
        <a href="/omp?cmd=new_task&amp;next=get_task&amp;filter={str:encode-uri (filters/term, true ())}&amp;filt_id={/envelope/params/filt_id}&amp;token={/envelope/token}"
           class="new-action-icon icon icon-sm" data-type="task"
           title="{gsa:i18n ('New Task')}">
          <img src="/img/new.svg"/>
        </a>
        <ul>
          <li>
            <a href="/omp?cmd=new_task&amp;next=get_task&amp;filter={str:encode-uri (filters/term, true ())}&amp;filt_id={/envelope/params/filt_id}&amp;token={/envelope/token}"
               class="new-action-icon" data-type="task"
               title="{gsa:i18n ('New Task')}">
              <xsl:value-of select="gsa:i18n ('New Task')"/>
            </a>
          </li>
          <li>
            <a href="/omp?cmd=new_container_task&amp;next=get_task&amp;filter={str:encode-uri (filters/term, true ())}&amp;filt_id={/envelope/params/filt_id}&amp;token={/envelope/token}"
               class="new-action-icon" data-type="container_task"
               title="{gsa:i18n ('New Container Task')}">
              <xsl:value-of select="gsa:i18n ('New Container Task')"/>
            </a>
          </li>
        </ul>
      </span>
    </xsl:when>
    <xsl:when test="gsa:may-op (concat ('create_', $type))">
      <!-- i18n with concat : see dynamic_strings.xsl - type-new -->
      <a href="/omp?cmd=new_{$type}&amp;next=get_{$type}&amp;filter={str:encode-uri ($filter, true ())}&amp;filt_id={$filt_id}&amp;{$type}_id={@id}&amp;token={/envelope/token}"
         class="new-action-icon icon icon-sm" data-type="{$type}" data-reload="window"
         title="{gsa:i18n (concat ('New ', $cap-type))}">
        <img src="/img/new.svg"/>
      </a>
    </xsl:when>
  </xsl:choose>
  <xsl:choose>
    <xsl:when test="$noupload"/>
    <xsl:when test="gsa:may-op (concat ('create_', $type))">
      <a href="/omp?cmd=upload_{$type}&amp;filter={str:encode-uri (gsa:envelope-filter (), true ())}&amp;filt_id={/envelope/params/filt_id}&amp;token={/envelope/token}"
         class="upload-action-icon icon icon-sm" data-type="port_list" data-reload="window"
         title="{gsa:i18n ('Import Port List')}">
        <img src="/img/upload.svg"/>
      </a>
    </xsl:when>
  </xsl:choose>
  <xsl:choose>
    <xsl:when test="$noclone"/>
    <xsl:when test="$grey-clone">
      <!-- i18n with concat : see dynamic_strings.xsl - type-action-denied -->
      <img src="/img/clone_inactive.svg"
           alt="{gsa:i18n ('Clone', 'Action Verb')}"
           value="Clone"
           title="{gsa:i18n (concat ($cap-type, ' may not be cloned'))}"
           class="icon icon-sm"/>
    </xsl:when>
    <xsl:when test="gsa:may-clone ($type, owner)">
      <xsl:choose>
        <xsl:when test="writable='0' and $type='permission'">
          <!-- i18n with concat : see dynamic_strings.xsl - type-action-denied -->
          <img src="/img/clone_inactive.svg"
               alt="{gsa:i18n ('Clone', 'Action Verb')}"
               value="Clone"
               title="{gsa:i18n (concat ($cap-type, ' must be owned or global'))}"
               class="icon icon-sm"/>
        </xsl:when>
        <xsl:otherwise>
          <div class="icon icon-sm ajax-post" data-reload="next" data-busy-text="{gsa:i18n ('Cloning...')}">
            <img src="/img/clone.svg"
              alt="{gsa:i18n ('Clone', 'Action Verb')}"
              title="{gsa:i18n ('Clone', 'Action Verb')}"/>
            <form action="/omp" method="post" enctype="multipart/form-data">
              <input type="hidden" name="token" value="{/envelope/token}"/>
              <input type="hidden" name="caller" value="{/envelope/current_page}"/>
              <input type="hidden" name="cmd" value="clone"/>
              <input type="hidden" name="resource_type" value="{$type}"/>
              <input type="hidden" name="next" value="get_{$type}"/>
              <input type="hidden" name="id" value="{@id}"/>
              <input type="hidden" name="filter" value="{gsa:envelope-filter ()}"/>
              <input type="hidden" name="filt_id" value="{/envelope/params/filt_id}"/>
            </form>
          </div>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
  </xsl:choose>
  <xsl:choose>
    <xsl:when test="$type = 'task'">
      <a href="/ng/{$type}s?filter={str:encode-uri ($filter, true ())}&amp;filt_id={$filt_id}"
        title="{gsa:i18n ($cap-type-plural)}" class="icon icon-sm">
        <img src="/img/list.svg" alt="{gsa:i18n ($cap-type-plural)}"/>
      </a>
    </xsl:when>
    <xsl:otherwise>
      <a href="/omp?cmd=get_{$type}s&amp;filter={str:encode-uri ($filter, true ())}&amp;filt_id={$filt_id}&amp;token={/envelope/token}"
        title="{gsa:i18n ($cap-type-plural)}" class="icon icon-sm">
        <img src="/img/list.svg" alt="{gsa:i18n ($cap-type-plural)}"/>
      </a>
    </xsl:otherwise>
  </xsl:choose>
  <span class="divider"/>
  <xsl:choose>
    <xsl:when test="$type = 'user'">
      <xsl:choose>
        <xsl:when test="name=/envelope/login/text()">
          <img src="/img/delete_inactive.svg" alt="{gsa:i18n ('Delete')}"
                title="{gsa:i18n ('Currently logged in as this user')}"
                class="icon icon-sm"/>
        </xsl:when>
        <xsl:when test="gsa:may (concat ('delete_', $type)) and writable!='0' and in_use='0'">
          <xsl:call-template name="delete-icon">
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="id" select="@id"/>
            <xsl:with-param name="params">
              <input type="hidden" name="filter" value="{$filter}"/>
              <input type="hidden" name="filt_id" value="{$filt_id}"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="inactive_text">
            <xsl:choose>
              <!-- i18n with concat : see dynamic_strings.xsl - type-action-denied -->
              <xsl:when test="in_use != '0'">
                <xsl:value-of select="gsa:i18n (concat ($cap-type, ' is still in use'))"/>
              </xsl:when>
              <xsl:when test="writable = '0'">
                <xsl:value-of select="gsa:i18n (concat ($cap-type, ' is not writable'))"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="gsa:i18n (concat ($cap-type, ' cannot be deleted'))"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <img src="/img/delete_inactive.svg" alt="{gsa:i18n ('Delete')}"
                title="{$inactive_text}"
                class="icon icon-sm"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="gsa:may (concat ('delete_', $type)) and writable!='0' and in_use='0'">
          <xsl:call-template name="trashcan-icon">
            <xsl:with-param name="type" select="$type"/>
            <xsl:with-param name="id" select="@id"/>
            <xsl:with-param name="params">
              <input type="hidden" name="filter" value="{$filter}"/>
              <input type="hidden" name="filt_id" value="{$filt_id}"/>
            </xsl:with-param>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:variable name="inactive_text">
            <xsl:choose>
              <!-- i18n with concat : see dynamic_strings.xsl - type-action-denied -->
              <xsl:when test="in_use != '0'">
                <xsl:value-of select="gsa:i18n (concat ($cap-type, ' is still in use'))"/>
              </xsl:when>
              <xsl:when test="writable = '0'">
                <xsl:value-of select="gsa:i18n (concat ($cap-type, ' is not writable'))"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="gsa:i18n (concat ($cap-type, ' cannot be moved to the trashcan'))"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <img src="/img/trashcan_inactive.svg" alt="{gsa:i18n ('To Trashcan', 'Action Verb')}"
                title="{$inactive_text}"
                class="icon icon-sm"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:choose>
    <xsl:when test="$noedit">
    </xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="gsa:may (concat ('modify_', $type)) and writable!='0'">
          <!-- i18n with concat : see dynamic_strings.xsl - type-edit -->
          <a href="/omp?cmd=edit_{$type}&amp;{$type}_id={@id}&amp;next=get_{$type}&amp;filter={str:encode-uri ($filter, true ())}&amp;filt_id={$filt_id}&amp;token={/envelope/token}" data-reload="window"
              class="edit-action-icon icon icon-sm" data-type="{$type}" data-id="{@id}"
              title="{gsa:i18n (concat ('Edit ', $cap-type))}">
            <img src="/img/edit.svg"/>
          </a>
        </xsl:when>
        <xsl:otherwise>
          <!-- i18n with concat : see dynamic_strings.xsl - type-action-denied -->
          <img src="/img/edit_inactive.svg" alt="{gsa:i18n ('Edit', 'Action Verb')}"
                title="{gsa:i18n (concat ($cap-type, ' is not writable'))}"
                class="icon icon-sm"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:choose>
    <xsl:when test="$noexport">
    </xsl:when>
    <xsl:otherwise>
      <!-- i18n with concat : see dynamic_strings.xsl - type-export-xml -->
      <a href="/omp?cmd=export_{$type}&amp;{$type}_id={@id}&amp;filter={str:encode-uri ($filter, true ())}&amp;filt_id={$filt_id}&amp;token={/envelope/token}"
          title="{gsa:i18n (concat ('Export ', $cap-type, ' as XML'))}"
          class="icon icon-sm">
        <img src="/img/download.svg" alt="{gsa:i18n ('Export XML', 'Action Verb')}"/>
      </a>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="gsad_msg">
  <xsl:call-template name="command_result_dialog">
    <xsl:with-param name="operation">
      <xsl:value-of select="@operation"/>
    </xsl:with-param>
    <xsl:with-param name="status">
      <xsl:value-of select="@status"/>
    </xsl:with-param>
    <xsl:with-param name="msg">
      <xsl:value-of select="@status_text"/>
    </xsl:with-param>
    <xsl:with-param name="details">
      <xsl:value-of select="text()"/>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="certificate-info-table">
  <xsl:param name="certificate_info"/>
  <table>
    <tr>
      <td><xsl:value-of select="gsa:i18n ('Activation', 'Certificate')"/>:</td>
      <td>
        <xsl:value-of select="$certificate_info/activation_time"/>
        <xsl:if test="$certificate_info/time_status = 'inactive'">
          <xsl:text> </xsl:text>
          <b>(<xsl:value-of select="gsa:i18n ('not active yet', 'Certificate')"/>)</b>
        </xsl:if>
      </td>
    </tr>
    <tr>
      <td><xsl:value-of select="gsa:i18n ('Expiration', 'Certificate')"/>:</td>
      <td>
        <xsl:value-of select="$certificate_info/expiration_time"/>
        <xsl:if test="$certificate_info/time_status = 'expired'">
          <xsl:text> </xsl:text>
          <b>(<xsl:value-of select="gsa:i18n ('expired', 'Certificate')"/>)</b>
        </xsl:if>
      </td>
    </tr>
    <tr>
      <td><xsl:value-of select="gsa:i18n ('MD5 Fingerprint')"/>:</td>
      <td><xsl:value-of select="$certificate_info/md5_fingerprint"/></td>
    </tr>
    <tr>
      <td><xsl:value-of select="gsa:i18n ('Issued by', 'Certificate')"/>:</td>
      <td><xsl:value-of select="$certificate_info/issuer"/></td>
    </tr>
  </table>
</xsl:template>

<xsl:template name="certificate-status">
  <xsl:param name="certificate_info"/>

  <xsl:choose>
    <xsl:when test="$certificate_info/time_status = 'expired'">
      <xsl:value-of select="gsa-i18n:strformat (gsa:i18n ('Certificate currently in use expired %1'), $certificate_info/expiration_time)"/>
    </xsl:when>
    <xsl:when test="$certificate_info/time_status = 'inactive'">
      <xsl:value-of select="gsa-i18n:strformat (gsa:i18n ('Certificate currently in use is not valid until %1'), $certificate_info/activation_time)"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="gsa-i18n:strformat (gsa:i18n ('Certificate currently in use will expire %1'), $certificate_info/expiration_time)"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="commands_response">
  <xsl:apply-templates/>
</xsl:template>

<!-- BEGIN REPORT DETAILS -->

<xsl:template match="get_reports_response">
  <xsl:choose>
    <xsl:when test="substring(@status, 1, 1) = '4' or substring(@status, 1, 1) = '5'">
      <xsl:call-template name="command_result_dialog">
        <xsl:with-param name="operation">
          Get Report
        </xsl:with-param>
        <xsl:with-param name="status">
          <xsl:value-of select="@status"/>
        </xsl:with-param>
        <xsl:with-param name="msg">
          <xsl:value-of select="@status_text"/>
        </xsl:with-param>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
      <xsl:for-each select="report">
            <xsl:apply-templates select="." mode="results"/>
      </xsl:for-each>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="get_report">
  <xsl:apply-templates select="create_note_response"/>
  <xsl:apply-templates select="create_override_response"/>
  <xsl:apply-templates select="create_filter_response"/>
  <xsl:apply-templates select="create_asset_response"/>
  <xsl:apply-templates select="create_report_response"/>
  <xsl:apply-templates select="delete_asset_response"/>
  <xsl:apply-templates select="gsad_msg"/>
  <xsl:apply-templates select="get_reports_alert_response/get_reports_response"
                       mode="alert"/>
  <xsl:apply-templates select="get_reports_response"/>
</xsl:template>

<!--     GET_REPORTS -->

<xsl:template match="get_reports">
  <xsl:apply-templates select="gsad_msg"/>
  <xsl:apply-templates select="delete_report_response"/>
  <xsl:apply-templates select="create_filter_response"/>
  <xsl:apply-templates select="create_report_response"/>
  <!-- The for-each makes the get_reports_response the current node. -->
  <xsl:for-each select="get_reports_response | commands_response/get_reports_response">
    <xsl:choose>
      <xsl:when test="substring(@status, 1, 1) = '4' or substring(@status, 1, 1) = '5'">
        <xsl:call-template name="command_result_dialog">
          <xsl:with-param name="operation">
            Get Reports
          </xsl:with-param>
          <xsl:with-param name="status">
            <xsl:value-of select="@status"/>
          </xsl:with-param>
          <xsl:with-param name="msg">
            <xsl:value-of select="@status_text"/>
          </xsl:with-param>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:for-each>
</xsl:template>

<!--     CREATE_NOTE_RESPONSE -->

<xsl:template match="create_note_response">
  <xsl:call-template name="command_result_dialog">
    <xsl:with-param name="operation">
      Create Note
    </xsl:with-param>
    <xsl:with-param name="status">
      <xsl:value-of select="@status"/>
    </xsl:with-param>
    <xsl:with-param name="msg">
      <xsl:value-of select="@status_text"/>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<!--     CREATE_OVERRIDE_RESPONSE -->

<xsl:template match="create_override_response">
  <xsl:call-template name="command_result_dialog">
    <xsl:with-param name="operation">
      Create Override
    </xsl:with-param>
    <xsl:with-param name="status">
      <xsl:value-of select="@status"/>
    </xsl:with-param>
    <xsl:with-param name="msg">
      <xsl:value-of select="@status_text"/>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<!--     DELETE_NOTE_RESPONSE -->

<xsl:template match="delete_note_response">
  <xsl:call-template name="command_result_dialog">
    <xsl:with-param name="operation">
      Delete Note
    </xsl:with-param>
    <xsl:with-param name="status">
      <xsl:value-of select="@status"/>
    </xsl:with-param>
    <xsl:with-param name="msg">
      <xsl:value-of select="@status_text"/>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<!--     DELETE_OVERRIDE_RESPONSE -->

<xsl:template match="delete_override_response">
  <xsl:call-template name="command_result_dialog">
    <xsl:with-param name="operation">
      Delete Override
    </xsl:with-param>
    <xsl:with-param name="status">
      <xsl:value-of select="@status"/>
    </xsl:with-param>
    <xsl:with-param name="msg">
      <xsl:value-of select="@status_text"/>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

<xsl:template name="cpe-icon">
  <xsl:param name="cpe"/>
  <xsl:param name="hide_other" select="0"/>
  <xsl:variable name="icon_data" select="document('cpe-icons.xml')/cpe_icon_dict/cpe_entry[contains($cpe, pattern)]"/>
  <xsl:choose>
    <xsl:when test="$icon_data != ''">
      <img src="/img/{$icon_data/icon}" class="icon icon-sm"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:if test="not($hide_other)">
        <img src="img/cpe/other.svg" class="icon icon-sm"/>
      </xsl:if>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- BEGIN MY SETTINGS MANAGEMENT -->

<xsl:template name="timezone-opts">
  <xsl:param name="timezone" select="'utc'"/>

  <xsl:choose>
    <xsl:when test="gsa:upper-case ($timezone) = 'UTC' or gsa:upper-case ($timezone) = 'COORDINATED UNIVERSAL TIME'">
      <option value="UTC" selected="1">Coordinated Universal Time</option>
    </xsl:when>
    <xsl:otherwise>
      <option value="UTC">Coordinated Universal Time</option>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:for-each select="document ('zones.xml')/zones/zone/name">
    <xsl:choose>
      <xsl:when test=". = $timezone">
        <option value="{.}" selected="1"><xsl:value-of select="translate (., '_',' ')"/></option>
      </xsl:when>
      <xsl:otherwise>
        <option value="{.}"><xsl:value-of select="translate (., '_',' ')"/></option>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:for-each>
</xsl:template>

<xsl:template name="timezone-select">
  <xsl:param name="timezone" select="'utc'"/>
  <xsl:param name="input-name" select="'text'"/>
  <xsl:param name="for-settings" select="0"/>

  <xsl:variable name="show_select" select="gsa:upper-case ($timezone) = 'UTC' or gsa:upper-case ($timezone) = 'COORDINATED UNIVERSAL TIME' or boolean (document ('zones.xml')/zones/zone[name=$timezone])"/>

  <xsl:choose>
    <xsl:when test="$show_select and $for-settings">
      <select name="{$input-name}" class="setting-control" data-setting="timezone">
        <xsl:call-template name="timezone-opts">
          <xsl:with-param name="timezone" select="$timezone"/>
        </xsl:call-template>
      </select>
    </xsl:when>
    <xsl:when test="$show_select">
      <select name="{$input-name}">
        <xsl:call-template name="timezone-opts">
          <xsl:with-param name="timezone" select="$timezone"/>
        </xsl:call-template>
      </select>
    </xsl:when>
    <xsl:when test="$for-settings">
      <input type="text" name="{$input-name}" size="40" maxlength="800"
             class="setting-control" data-setting="timezone"
             value="{gsa:param-or ('text', $timezone)}"/>
    </xsl:when>
    <xsl:otherwise>
      <input type="text" name="{$input-name}" size="40" maxlength="800"
             value="{gsa:param-or ('text', $timezone)}"/>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- BEGIN BULK ACTION MANAGEMENT -->

<xsl:template match="process_bulk">
  <xsl:variable name="resources" select="selections/selection/@id"/>
  <div class="gb_window" style="width:500px">
    <div class="gb_window_part_left"></div>
    <div class="gb_window_part_right"></div>
    <div class="gb_window_part_center"><xsl:value-of select="gsa:i18n ('Confirm action')"/></div>
    <div class="gb_window_part_content">
      <form style="display:inline;" method="post" enctype="multipart/form-data">
        <div>
          <xsl:choose>
            <!-- i18n with concat : see dynamic_strings.xsl - type-bulk-delete-confirm -->
            <xsl:when test="action = 'delete'">
              <p class="text-center">
                <xsl:value-of select="gsa-i18n:strformat (gsa:n-i18n (concat ('%1 ', gsa:type-name (type), ' will be deleted'), concat ('%1 ', gsa:type-name-plural (type), ' will be deleted'), count($resources)), count($resources))"/>
                <input type="hidden" name="cmd" value="bulk_delete"/>
              </p>
            </xsl:when>
            <!-- i18n with concat : see dynamic_strings.xsl - type-bulk-trash-confirm -->
            <xsl:when test="action = 'trash'">
              <p class="text-center">
                <xsl:value-of select="gsa-i18n:strformat (gsa:n-i18n (concat ('%1 ', gsa:type-name (type), ' will be moved to the trashcan'), concat ('%1 ', gsa:type-name-plural (type), ' will be moved to the trashcan'), count($resources)), count($resources))"/>
                <input type="hidden" name="cmd" value="bulk_delete"/>
              </p>
            </xsl:when>
          </xsl:choose>

          <xsl:choose>
            <xsl:when test="action='delete' and type='user'">
              <div>
                <xsl:value-of select="gsa:i18n ('If no inheriting user is selected, all owned resources will be deleted as well.')"/>
              </div>
              <p>
                <xsl:value-of select="gsa:i18n ('Inheriting user')"/>:
                <xsl:variable name="inheritor_id" select="''"/>
                <select name="inheritor_id" style="text-align:left;">
                  <xsl:call-template name="opt">
                    <xsl:with-param name="value" select="''"/>
                    <xsl:with-param name="select-value" select="$inheritor_id"/>
                    <xsl:with-param name="content" select="'--'"/>
                  </xsl:call-template>
                  <xsl:call-template name="opt">
                    <xsl:with-param name="value" select="'self'"/>
                    <xsl:with-param name="select-value" select="$inheritor_id"/>
                    <xsl:with-param name="content" select="concat ('(', gsa:i18n ('Current User'), ')')"/>
                  </xsl:call-template>
                  <xsl:for-each select="get_users_response/user">
                    <xsl:variable name="selection_id" select="@id"/>
                    <xsl:if test="count($resources [. = $selection_id]) = 0">
                      <xsl:call-template name="opt">
                        <xsl:with-param name="value" select="@id"/>
                        <xsl:with-param name="select-value" select="$inheritor_id"/>
                        <xsl:with-param name="content" select="name"/>
                      </xsl:call-template>
                    </xsl:if>
                  </xsl:for-each>
                </select>
              </p>
            </xsl:when>
          </xsl:choose>

          <xsl:for-each select="/envelope/params/*">
            <xsl:choose>
              <xsl:when test="starts-with (name (), 'bulk_') or name() = 'cmd' or (name() = '_param' and starts-with (name, 'bulk_'))">
              </xsl:when>
              <xsl:when test="name() = '_param'">
                <input type="hidden" name="{name}" value="{value}"/>
              </xsl:when>
              <xsl:otherwise>
                <input type="hidden" name="{name()}" value="{text()}"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:for-each>

          <xsl:for-each select="$resources">
            <input type="hidden" name="bulk_selected:{.}" value="1"/>
          </xsl:for-each>
        </div>
        <input type="submit" value="OK"/>
      </form>
    </div>
  </div>
</xsl:template>

<!-- BEGIN PROTOCOL DOC MANAGEMENT -->

<xsl:include href="omp-doc.xsl"/>

<xsl:template name="protocol">
  <div class="toolbar">
    <div class="small_inline_form" style="display: inline; font-weight: normal;">
      <form action="" method="get">
        <input type="hidden" name="token" value="{/envelope/token}"/>
        <input type="hidden" name="cmd" value="export_omp_doc"/>
        <select style="margin-bottom: 0px;" name="protocol_format" size="1">
          <option value="html" selected="1">HTML</option>
          <option value="rnc">RNC</option>
          <option value="xml">XML</option>
        </select>
        <input type="image"
          name="Download GMP documentation"
          src="/img/download.svg"
          class="icon icon-sm"
          alt="Download"/>
      </form>
    </div>
  </div>

  <div class="section-header">
    <h1>
      <a href="/omp?cmd=get_protocol_doc&amp;token={/envelope/token}"
         title="{gsa:i18n ('Help: GMP')}">
        <img class="icon icon-lg" src="/img/help.svg" alt="Help: GMP"/>
      </a>
      <xsl:value-of select="gsa:i18n ('Help: GMP')"/>
    </h1>
  </div>

  <div class="section-box">
    <div>
      <a href="/help/contents.html?token={/envelope/token}">Help Contents</a>i
    </div>
    <div style="text-align:left">
      <h1>GMP</h1>

      <xsl:if test="version">
        <p>Version: <xsl:value-of select="normalize-space(version)"/></p>
      </xsl:if>

      <xsl:if test="summary">
        <p><xsl:value-of select="normalize-space(summary)"/>.</p>
      </xsl:if>

      <h2 id="contents">Contents</h2>
      <ol>
        <li><a href="#type_summary">Summary of Data Types</a></li>
        <li><a href="#element_summary">Summary of Elements</a></li>
        <li><a href="#command_summary">Summary of Commands</a></li>
        <li><a href="#rnc_preamble">RNC Preamble</a></li>
        <li><a href="#type_details">Data Type Details</a></li>
        <li><a href="#element_details">Element Details</a></li>
        <li><a href="#command_details">Command Details</a></li>
        <li>
          <a href="#changes">
            Compatibility Changes in Version
            <xsl:value-of select="version"/>
          </a>
        </li>
      </ol>

      <xsl:call-template name="type-summary"/>
      <xsl:call-template name="element-summary"/>
      <xsl:call-template name="command-summary"/>
      <xsl:call-template name="rnc-preamble"/>
      <xsl:call-template name="type-details"/>
      <xsl:call-template name="element-details"/>
      <xsl:call-template name="command-details"/>
      <xsl:call-template name="changes"/>
    </div>
  </div>
</xsl:template>

<xsl:template match="get_protocol_doc">
  <xsl:apply-templates select="gsad_msg"/>
  <xsl:for-each select="help_response/schema/protocol">
    <xsl:call-template name="protocol"/>
  </xsl:for-each>
</xsl:template>

</xsl:stylesheet>
