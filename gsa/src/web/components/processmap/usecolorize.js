/* Copyright (C) 2020 Greenbone Networks GmbH
 *
 * SPDX-License-Identifier: GPL-2.0-or-later
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110-1301 USA.
 */

import {useSelector} from 'react-redux';

import {hostsFilter} from 'web/pages/processmaps/dashboard/processmaploader';

import {selector as hostSelector} from 'web/store/entities/hosts';

import {
  severityRiskFactor,
  LOG,
  LOG_VALUE,
  LOW,
  MEDIUM,
  HIGH,
} from 'web/utils/severity';
import Theme from 'web/utils/theme';

const getMaxSeverity = (hostEntities = []) => {
  const severities = [];
  for (const host of hostEntities) {
    severities.push(host.severity);
  }
  return Math.max(...severities);
};

const getSeverityColor = severity => {
  const riskFactor = severityRiskFactor(severity);
  let color;
  if (riskFactor === LOG) {
    color = Theme.lightGray;
  } else if (riskFactor === MEDIUM) {
    color = Theme.severityWarnYellow;
  } else if (riskFactor === HIGH) {
    color = Theme.errorRed;
  } else if (riskFactor === LOW) {
    color = Theme.severityLowBlue;
  } else {
    color = Theme.white;
  }
  return color;
};

const useColorize = (processMap = {}, applyConditionalColorization) => {
  let hostFilter;
  const procMap = {...processMap};
  const {processes = {}, edges = {}} = procMap;
  useSelector(rootState => {
    // get the initial severities and colors for processes
    for (const procId in processes) {
      const {tagId} = processes[procId];
      hostFilter = hostsFilter(tagId);
      const hostSel = hostSelector(rootState);
      const hostEntities = hostSel.getEntities(hostFilter);
      const isLoadingHosts = hostSel.isLoadingEntities(hostFilter);
      const maxSeverity = getMaxSeverity(hostEntities);
      if (!isLoadingHosts) {
        procMap.processes[procId].color = getSeverityColor(maxSeverity);
        procMap.processes[procId].severity = maxSeverity;
        procMap.processes[procId].derivedSeverity = maxSeverity;
      }
    }
    if (applyConditionalColorization) {
      let updated = true;
      // loop through edges until no more processes received an update
      while (updated) {
        updated = false;
        for (const edge of Object.values(edges)) {
          const {source: sourceId, target: targetId} = edge;
          const source = procMap.processes[sourceId];
          const target = procMap.processes[targetId];

          if (
            source.derivedSeverity > target.derivedSeverity &&
            source.derivedSeverity !== LOG_VALUE
          ) {
            // if source.derivedSeverity is not LOG
            procMap.processes[targetId].color = getSeverityColor(
              source.derivedSeverity,
            );
            procMap.processes[targetId].derivedSeverity =
              source.derivedSeverity;
            updated = true;
          }
        }
      }
    }
  });

  return procMap;
};

export default useColorize;

// vim: set ts=2 sw=2 tw=80:
