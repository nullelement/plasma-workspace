/*
    Copyright (C) 2021 Kai Uwe Broulik <kde@broulik.de>

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 2.1 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public
    License along with this library; if not, write to the Free Software
    Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
*/

#include "fileinfo.h"

#include <QMimeDatabase>
#include <QTimer>

#include <KFileItemActions>
#include <KIO/MimetypeJob>

Application::Application() = default;

Application::Application(const KService::Ptr &service)
    : m_service(service)
{
    Q_ASSERT(service->isValid());
}

QString Application::name() const
{
    return m_service ? m_service->name() : QString();
}

QString Application::iconName() const
{
    return m_service ? m_service->icon() : QString();
}

bool Application::isValid() const
{
    return m_service && m_service->isValid();
}

FileInfo::FileInfo(QObject *parent)
    : QObject(parent)
{

}

FileInfo::~FileInfo() = default;

QUrl FileInfo::url() const
{
    return m_url;
}

void FileInfo::setUrl(const QUrl &url)
{
    if (m_url != url) {
        m_url = url;
        reload();
        emit urlChanged(url);
    }
}

bool FileInfo::busy() const
{
    return m_busy;
}

void FileInfo::setBusy(bool busy)
{
    if (m_busy != busy) {
        m_busy = busy;
        emit busyChanged(busy);
    }
}

int FileInfo::error() const
{
    return m_error;
}

void FileInfo::setError(int error)
{
    if (m_error != error) {
        m_error = error;
        emit errorChanged(error);
    }
}

QString FileInfo::mimeType() const
{
    return m_mimeType;
}

QString FileInfo::iconName() const
{
    return m_iconName;
}

Application FileInfo::preferredApplication() const
{
    return m_preferredApplication;
}

void FileInfo::reload()
{
    if (!m_url.isValid()) {
        return;
    }

    if (m_job) {
        m_job->kill();
    }

    setError(0);

    // Do a quick guess by file name while we wait for the job to find the mime type
    QString guessedMimeType;

    const auto types = QMimeDatabase().mimeTypesForFileName(m_url.fileName());
    if (!types.isEmpty()) {
        const QMimeType type = types.first();
        if (!type.isDefault()) {
            guessedMimeType = type.name();
        }
    }

    mimeTypeFound(guessedMimeType);

    m_job = KIO::mimetype(m_url, KIO::HideProgressInfo);
    m_job->addMetaData(QStringLiteral("no-auth-prompt"), QStringLiteral("true"));

    QTimer::singleShot(500, this, [this] {
        if (m_job) {
            setBusy(true);
        }
    });

    connect(m_job, &KIO::MimetypeJob::mimeTypeFound, this, [this](KJob *job, const QString &mimeType) {
        Q_UNUSED(job);
        mimeTypeFound(mimeType);
        // No point in fetching any further
        m_job->kill();
        m_job = nullptr;
        setBusy(false);
    });

    connect(m_job, &KIO::MimetypeJob::result, this, [this] {
        setError(m_job->error());
        if (m_job->error()) {
            qWarning() << "Failed to determine mime type for" << m_job->url() << m_job->errorString();
        }

        m_job = nullptr;
        setBusy(false);
    });
}

void FileInfo::mimeTypeFound(const QString &mimeType)
{
    if (m_mimeType == mimeType) {
        return;
    }

    m_mimeType = mimeType;

    KService::List associatedApps;

    if (!mimeType.isEmpty()) {
        const auto type = QMimeDatabase().mimeTypeForName(mimeType);
        m_iconName = type.iconName();

        associatedApps = KFileItemActions::associatedApplications({mimeType}, {});
    } else {
        m_iconName.clear();
    }

    if (!associatedApps.isEmpty()) {
        m_preferredApplication = Application(associatedApps.first());
    }

    emit mimeTypeChanged();
}
