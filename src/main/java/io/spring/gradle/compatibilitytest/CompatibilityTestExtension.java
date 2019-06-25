/*
 * Copyright 2014-2019 the original author or authors.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package io.spring.gradle.compatibilitytest;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.gradle.api.Action;

import io.spring.gradle.compatibilitytest.CompatibilityMatrix.DependencyVersion;

/**
 * DSL extension for configuring compatibility {@link Test} tasks.
 *
 * @author Andy Wilkinson
 */
public class CompatibilityTestExtension {

	private final CompatibilityMatrix testMatrix;

	CompatibilityTestExtension(CompatibilityMatrix testMatrix) {
		this.testMatrix = testMatrix;
	}

	/**
	 * Creates a new entry in the matrix for a dependency with the given {@code name}.
	 * The {@code configurer} is called to configure the entry.
	 *
	 * @param name name of the dependency
	 * @param configurer provides further configuration of the dependency
	 */
	public void dependency(String name, Action<DependencyConfigurer> action) {
		DependencyConfigurer configurer = new DependencyConfigurer();
		action.execute(configurer);
		Set<DependencyVersion> dependencyVersions = configurer.versions.stream().map((version) -> new DependencyVersion(name, configurer.getGroupId(), configurer.getArtifactId(), version)).collect(Collectors.toSet());
		this.testMatrix.add(dependencyVersions);
	}

	/**
	 * Configurer for an entry in a {@link CompatibilityMatrix} that controls the versions of a
	 * dependency or set of dependencies identified by a {@link groupId} and optional
	 * {@link artifactId}.
	 */
	public static class DependencyConfigurer {

		private String groupId;

		private String artifactId;

		private List<String> versions = new ArrayList<>();

		public String getGroupId() {
			return groupId;
		}

		public void setGroupId(String groupId) {
			this.groupId = groupId;
		}

		public String getArtifactId() {
			return artifactId;
		}

		public void setArtifactId(String artifactId) {
			this.artifactId = artifactId;
		}

		public List<String> getVersions() {
			return versions;
		}

		public void setVersions(List<String> versions) {
			this.versions = versions;
		}

	}

}
